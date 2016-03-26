require 'set'

module GitWalker
  module Metrics
    def self.no_of_authors(filepath, repo)
      repo.gblob(filepath).log.each_with_object(Set.new) do |commit, authors|
        authors.add(commit.author.email)
      end.count
    end
  end
end
