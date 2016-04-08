module Diggit
  module Analyse
    module RefactorDiligence
      class Report
        def initialize(repo, head:, base:)
          @repo = repo
          @head = head
          @base = base
        end

        def generate
        end

        def ruby_files_changed

        end
      end
    end
  end
end
