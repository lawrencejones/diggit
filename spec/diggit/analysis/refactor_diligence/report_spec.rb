require 'diggit/analysis/refactor_diligence/report'
require_relative '../temporary_analysis_repo'

# rubocop:disable Metrics/MethodLength
def refactor_diligence_test_repo
  TemporaryAnalysisRepo.create do |repo|
    repo.write('master.rb', <<-RUBY)
    class Master
      def initialize
      end
    end
    RUBY
    repo.commit('initial Master::initialize')

    repo.write('python_file.py', <<-PYTHON)
    class PythonFile(object):

    \tdef __init__(self, file):
    \t\tself.file = file
    \t\tprint(self.file)
    PYTHON
    repo.commit('initial PythonFile::__init__')

    repo.write('master.rb', <<-RUBY)
    class Master
      def initialize
        puts('first line')
      end
    end
    RUBY
    repo.commit('Master::initialize +1')

    repo.write('python_file.py', <<-PYTHON)
    class PythonFile(object):

    \tdef __init__(self, file):
    \t\tself.file = file
    \t\tprint(self.file)
    \t\tprint('Adding another line')
    PYTHON
    repo.commit('PythonFile::__init__ +1')

    repo.write('master.rb', <<-RUBY)
    class Master
      def initialize
        puts('first line')
        puts('second line')
      end
    end
    RUBY
    repo.commit('Master::initialize, PythonFile::__init__ +2')

    # Start feature branch here
    repo.branch('feature')

    repo.write('file.rb', <<-RUBY)
    module Utils
      class Socket
        def initialize(host)
          @host = host
        end
      end
    end
    RUBY
    repo.commit('initial Utils::Socket')

    repo.write('file.rb', <<-RUBY)
    module Utils
      class Socket
        def initialize(host, port)
          @host = host
          @port = port
        end
      end
    end
    RUBY
    repo.commit('add port')

    repo.write('file.rb', <<-RUBY)
    module Utils
      class Socket
        def self.from_uri(uri)
          host, port = URI.parse(uri)
          new(host, port)
        end

        def initialize(host, port)
          @host = host
          @port = port
          puts("Created new socket on \#{host}:\#{port}")
        end
      end
    end
    RUBY
    repo.write('master.rb', <<-RUBY)
    class Master
      def initialize
        puts('first line')
        puts('second line')
      end

      def add_a_method
      end
    end
    RUBY
    repo.write('python_file.py', <<-PYTHON)
    class PythonFile(object):

    \tdef __init__(self, file):
    \t\tself.file = file
    \t\tprint(self.file)
    \t\tprint('Adding another line')
    \t\tprint('Second file increase')
    PYTHON
    repo.commit('.from_uri and log, PythonFile::__init__ +1')

    # Start non-parseable branch here
    repo.branch('non-parseable')
    repo.write('main.c', %(int main(int argc, char **argv) { return 0; }))
    repo.commit('unparseable file')
  end
end

RSpec.describe(Diggit::Analysis::RefactorDiligence::Report) do
  subject(:report) { described_class.new(repo, { base: base, head: head }, config) }
  let(:repo) { refactor_diligence_test_repo }

  def branch_oid(branch)
    repo.branches.find { |b| b.name == branch }.target.oid
  end

  let(:head) { branch_oid('feature') }
  let(:base) { branch_oid('master') }

  let(:config) do
    { min_method_size: min_method_size,
      times_increased_threshold: threshold,
      ignore: ignore }
  end
  let(:threshold) { 2 }
  let(:min_method_size) { 1 }
  let(:ignore) { [] }

  it 'defines a name' do
    expect(described_class::NAME).to eql('RefactorDiligence')
  end

  describe '#comments' do
    subject(:comments) { report.comments }

    def comment_for(method)
      comments.find { |c| c[:meta][:method_name][method] }
    end
    let(:socket_comment) { comment_for(/Socket::initialize/) }
    let(:master_comment) { comment_for(/Master::initialize/) }
    let(:python_comment) { comment_for(/PythonFile::__init__/) }

    context 'when pull does not change parseable files' do
      let(:head) { branch_oid('non-parseable') }
      let(:base) { branch_oid('feature') }

      it { is_expected.to eql([]) }
    end

    context 'when method sizes include below MIN_METHOD_SIZE' do
      let(:threshold) { 1 }
      let(:min_method_size) { 3 }

      it 'does not include those histories' do
        expect(python_comment[:meta]).to include(times_increased: 2)
        expect(socket_comment[:meta]).to include(times_increased: 2)
      end
    end

    it 'does not include methods that have not increased in size in this diff' do
      expect(master_comment).to be_nil
    end

    it 'includes python methods that are above threshold' do
      expect(python_comment).to include(
        report: 'RefactorDiligence',
        message: /has increased in size the last 3 times/i,
        location: 'python_file.py:3',
        index: 'PythonFile::__init__',
        meta: {
          method_name: 'PythonFile::__init__',
          times_increased: 3,
        }
      )
    end

    it 'includes ruby methods that are above threshold' do
      expect(socket_comment).to include(
        report: 'RefactorDiligence',
        message: /has increased in size the last 3 times/i,
        location: 'file.rb:8',
        index: 'Utils::Socket::initialize',
        meta: {
          method_name: 'Utils::Socket::initialize',
          times_increased: 3,
        }
      )
    end

    it 'tags commit shas in comment' do
      shas_in_comment = socket_comment[:message].scan(/\S{40}/)
      expect(shas_in_comment.size).to be(3)
      shas_in_comment.each { |sha| expect(repo.exists?(sha)).to be(true) }
    end

    it 'does not include methods below threshold' do
      from_uri = comments.find { |c| c[:meta][:method_name][/from_uri/] }
      expect(from_uri).to be_nil
    end

    context 'when target file is in ignored' do
      let(:ignore) { ['file.rb'] }

      it 'does not comment' do
        expect(socket_comment).to be_nil
      end
    end
  end
end
