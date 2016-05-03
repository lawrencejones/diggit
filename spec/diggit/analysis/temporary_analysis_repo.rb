require 'git'
require 'fileutils'
require 'diggit/services/environment'

class TemporaryAnalysisRepo
  @repos = []

  def self.create(&block)
    new.tap { |repo| block.call(repo) }.g
  end

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

  def commit(message, time: Time.now)
    Diggit::Services::Environment.with_temporary_env(git_time_env(time)) do
      g.add(all: true)
      g.commit_all(message)
    end
  end

  private

  def git_time_env(time)
    { 'GIT_AUTHOR_DATE' => time.to_s,
      'GIT_COMMITTER_DATE' => time.to_s }
  end
end
