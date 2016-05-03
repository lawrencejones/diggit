require_relative '../temporary_analysis_repo'

# rubocop:disable Metrics/MethodLength, Style/AlignParameters
def refactor_diligence_test_repo
  TemporaryAnalysisRepo.new.tap do |repo|
    repo.write('master.rb',
    %(class Master
        def initialize
        end
      end))
    repo.commit('initial Master::initialize')

    repo.write('master.rb',
    %(class Master
        def initialize
          puts('first line')
        end
      end))
    repo.commit('Master::initialize +1')

    repo.write('master.rb',
    %(class Master
        def initialize
          puts('first line')
          puts('second line')
        end
      end))
    repo.commit('Master::initialize +2')

    # Start feature branch here
    repo.g.branch('feature').checkout

    repo.write('file.rb',
    %(module Utils
        class Socket
          def initialize(host)
            @host = host
          end
        end
      end))
    repo.commit('initial Utils::Socket')

    repo.write('file.rb',
    %(module Utils
        class Socket
          def initialize(host, port)
            @host = host
            @port = port
          end
        end
      end))
    repo.commit('add port')

    repo.write('file.rb',
    %(module Utils
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
      end))
    repo.write('master.rb',
    %(class Master
        def initialize
          puts('first line')
          puts('second line')
        end

        def add_a_method
        end
      end))
    repo.commit('.from_uri and log')

    # Start non-ruby branch here
    repo.g.branch('non-ruby').checkout
    repo.write('main.c', %(int main(int argc, char **argv) { return 0; }))
    repo.commit('non-ruby file')
  end.g
end
