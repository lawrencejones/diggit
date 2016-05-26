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
