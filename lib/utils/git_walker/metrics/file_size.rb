module GitWalker
  module Metrics
    def self.file_size(filepath, _repo)
      File.size(filepath)
    end
  end
end
