#!/usr/bin/env ruby
require 'json'
require 'fileutils'

def usage
  prog = File.basename(__FILE__)
  puts %(
    Desc:  Walk given repo to output file tree
    Usage: #{prog} <repo> <metric>
    Examples...

        #{prog} /Projects/arm file-size
        #{prog} /Projects/linux lines-of-code

    Example output...

        {
          "path": "/dir",
          "score": 123,
          "items": {
            "file": {
              "path": "/dir/file",
              "score": 123
            }
          }
        }

    NB: More complex use cases (such as filtering files) should require
        the GitWalker and instrument from there.
  )
end

def main
  usage || exit(-1) unless ARGV.count == 2
  root, metric_label = ARGV

  metric = {
    'file-size' => ->(target) { File.size(target) },
    'lines-of-code' => lambda(target) do
      return 0 if File.directory?(target)

      `wc -l "#{target}"`.split.first.to_i
    end,
  }.fetch(metric_label)

  puts(JSON.pretty_generate(GitWalker.new(root, metric_lambda: metric).frame))
end

# Walks a given git repo to produce a recursive structure of each directory and file
# found from the root, computing a score for each file/directory using the supplied block.
#
# Example of...
#
#     GitWalker.new(repo_path, metric_lambda: ->(target) { File.size(target) })
#
# ...would walk the repo at `repo_path`, computing the recursive file size of each
# file/directory that is tracked by the repo.
class GitWalker
  def initialize(root, metric_lambda: nil)
    @root = File.realpath(root)
    verify_root!

    @metric_lambda = metric_lambda
    @frame = compute_frame
  end

  attr_reader :frame, :root

  private

  def verify_root!
    unless git_exec('rev-parse --is-inside-work-tree') == 'true'
      fail "Is not valid git repository! #{@root}"
    end
  end

  def git_exec(cmd)
    `GIT_DIR="#{@root}/.git" git #{cmd}`.chomp
  end

  def all_tracked_files
    git_exec('ls-files').split
  end

  def compute_frame
    all_tracked_files.each_with_object(new_frame) do |file, frame|
      frame_score = compute_metric(file)
      next if frame_score == 0

      frame[:score] += frame_score

      directories = file.split(File::SEPARATOR)
      basename = directories.pop

      sub_frame = directories.reduce(frame) do |frm, dir|
        frm[:items][dir] ||= new_frame(File.join(frm[:path], dir))
        frm[:items][dir].tap { |f| f[:score] += frame_score }
      end

      sub_frame[:items][basename] = {
        path: File.join(File.basename(@root), file),
        score: frame_score,
      }
    end
  end

  def new_frame(path = File.basename(@root))
    { path: path, items: {}, score: 0 }
  end

  def compute_metric(target)
    @metric_lambda[File.join(@root, target)]
  end
end

# Run as a script if running as an executable
main if __FILE__ == $PROGRAM_NAME

RSpec.describe(GitWalker) do
  subject(:walker) do
    described_class.new(@tmp, metric_lambda: metric)
  end

  let(:metric) { ->(target) { File.size(target) } }

  before(:all) do
    @tmp = Dir.mktmpdir

    fail 'Bad setup command' unless system %(
    set -e

    mkdir #{@tmp}/root
    cd #{@tmp}
    git init
    touch "#{@tmp}/root/zero"
    dd if=/dev/zero of="#{@tmp}/root/1K"  bs=1k  count=1
    dd if=/dev/zero of="#{@tmp}/root/2M"  bs=1024k  count=2
    git add -A
    git commit -am "Initial commit"
    )
  end

  after(:all) { FileUtils.rm_rf(@tmp) }

  def flatten_frames(frame)
    [frame, *frame.fetch(:items, {}).values.flat_map { |frm| flatten_frames(frm) }]
  end

  describe '.frame' do
    subject(:frame) { walker.frame }
    let(:all_frames) { flatten_frames(frame) }

    it 'computes all paths from basename of repo' do
      all_frames.each do |frame|
        expect(frame[:path]).to start_with(File.basename(@tmp))
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
  end
end if defined?(RSpec)
