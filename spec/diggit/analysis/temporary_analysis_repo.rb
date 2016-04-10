require 'git'
require 'fileutils'

class TemporaryAnalysisRepo
  @repos = []

  def self.clean!
    @repos.map { |repo| FileUtils.rm_rf(repo.base) }
  end

  def self.schedule_for_removal(repo)
    @repos << repo
  end

  def initialize(base = Dir.mktmpdir)
    @base = base
    @g = Git.init(base)
    self.class.schedule_for_removal(self)
  end

  attr_reader :base, :g

  def write(file, contents)
    File.write(File.join(base, file), contents)
  end

  def commit(message)
    g.add(all: true)
    g.commit_all(message)
  end
end
