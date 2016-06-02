module Diggit
  module Analysis
    module ChangePatterns
      # Discovers appropriate minimum support parameter for given changesets.
      #
      # Selects the minimum support that yields results in less than TIMEOUT
      # seconds or that includes PCT_FILES_INCLUDED% of the given files in
      # the repo.
      class MinSupportFinder
        TIMEOUT = 60.seconds
        PCT_FILES_INCLUDED = 20

        def initialize(algorithm, changesets)

        end
      end
    end
  end
end
