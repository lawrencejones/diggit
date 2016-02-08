module GitWalker
  module Metrics
    def self.lines_of_code(filepath, _repo)
      contents = File.read(filepath)
      return 0 unless contents.valid_encoding?

      contents.lines.count { |line| line[/\S/] }
    end
  end
end
