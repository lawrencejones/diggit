module GitWalker
  module Metrics
    def self.lines_of_code(filepath, _repo)
      File.read(filepath).lines.count { |line| line[/\S/] }
    end
  end
end
