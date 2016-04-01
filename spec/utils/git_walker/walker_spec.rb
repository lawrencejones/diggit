require 'tmpdir'
require 'git'
require 'fileutils'

require 'utils/git_walker/walker'

def create_random_file!(path, block_size, count)
  stderr = `dd if=/dev/zero of="#{path}" bs=#{block_size} count=#{count} 2>&1`

  unless $CHILD_STATUS.to_i == 0
    STDERR.puts("\n", stderr)
    STDERR.puts("dd exited with status #{$CHILD_STATUS.to_i}\n")

    exit($CHILD_STATUS.to_i)
  end
end

# Creates a repo with some dummy files of specific sizes.
def construct_temporary_repo(repo_path)
  FileUtils.mkdir_p(File.join(repo_path, 'root'))
  repo = Git.init(repo_path)
  FileUtils.touch(File.join(repo_path, 'root', 'zero'))

  create_random_file!(File.join(repo_path, 'root', '1K'), '1k', 1)
  create_random_file!(File.join(repo_path, 'root', '2M'), '1024k', 2)

  repo.add
  repo.commit('Initial commit')
end

def flatten_frames(frame)
  [frame, *frame.fetch(:items, {}).values.flat_map { |frm| flatten_frames(frm) }]
end

RSpec.describe(GitWalker::Walker) do
  subject(:walker) do
    described_class.new(repo_path, metric_lambda: metric, file_glob: file_glob)
  end

  let(:repo_path) { Dir.mktmpdir }
  let(:file_glob) { nil }
  let(:metric) { ->(target, _repo) { File.size(target) } }

  before { construct_temporary_repo(repo_path) }
  after  { FileUtils.rm_rf(repo_path) }

  describe '.new' do
    context 'with valid git repo' do
      it 'succeeds' do
        expect { walker }.not_to raise_exception
      end
    end

    context 'with invalid git repo' do
      it 'raises exception' do
        Dir.mktmpdir do |dir|
          expect { GitWalker::Walker.new(dir) }.
            to raise_exception(/not valid git repo/i)
        end
      end
    end
  end

  describe '.frame' do
    subject(:frame) { walker.frame }
    let(:all_frames) { flatten_frames(frame) }

    it 'computes all paths from basename of repo' do
      all_frames.each do |frame|
        expect(frame[:path]).to start_with(File.basename(repo_path))
      end
    end

    it 'does not produce frames that have scores of 0' do
      expect(frame[:items]['root'][:items]).not_to include('zero')
    end

    it 'computes metric for files', :aggregate_failures do
      expect(frame[:items]['root'][:items]['1K'][:score]).to eq(1 << 10) # 1KB
      expect(frame[:items]['root'][:items]['2M'][:score]).to eq(2 * (1 << 20)) # 2MB
    end

    it 'aggregates metric for directories' do
      expect(frame[:score]).to be_within(1 << 9).of((1 << 10) + (2 * (1 << 20)))
    end

    context 'with file glob' do
      let(:file_glob) { '**/1*' }
      let(:walked_files) { all_frames.map { |f| File.basename(f[:path]) } }

      it 'filters out files not matched by pattern' do
        expect(walked_files).to include('1K')
        expect(walked_files).not_to include('2M')
      end

      context 'of multiple files' do
        let(:file_glob) { '**/{1K,2M}' }

        it 'permits each pattern' do
          expect(walked_files).to include('1K', '2M')
        end
      end
    end
  end
end
