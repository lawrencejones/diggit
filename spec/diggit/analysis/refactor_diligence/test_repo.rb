require_relative '../temporary_analysis_repo'

# rubocop:disable Metrics/MethodLength, Style/AlignParameters
def refactor_diligence_test_repo
  TemporaryAnalysisRepo.new.tap do |repo|
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
    repo.commit('.from_uri and log')
  end.g
end
