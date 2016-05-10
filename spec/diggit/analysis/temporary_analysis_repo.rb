require 'rugged'
require 'fileutils'

class TemporaryAnalysisRepo
  @repos = []

  def self.create(&block)
    new.tap(&block).repo
  end

  def self.clean!
    @repos.map(&:destroy)
  end

  def self.schedule_for_removal(repo)
    @repos << repo
  end

  def initialize(base = Dir.mktmpdir)
    @repo = Rugged::Repository.init_at(base)
    commit('Initial commit')
    self.class.schedule_for_removal(self)
  end

  attr_reader :repo

  def branch(branch)
    repo.branches.create(branch, 'HEAD')
    repo.checkout(branch)
  end

  def write(path, contents)
    repo.index.tap do |index|
      File.write(File.join(repo.workdir, path), contents)
      index.add(path: path, oid: Rugged::Blob.from_workdir(repo, path), mode: 0100644)
    end
  end

  def rm(path)
    repo.index.tap do |index|
      File.unlink(File.join(repo.workdir, path))
      index.remove(path)
    end
  end

  def commit(message, time: Time.now)
    commit_tree = repo.index.write_tree(repo)
    repo.index.write

    person = { email: 'git@test.com', name: 'Test', time: time }
    Rugged::Commit.
      create(repo,
             message: message,
             tree: commit_tree,
             author: person, committer: person,
             parents: repo.empty? ? [] : [repo.head.target].compact,
             update_ref: 'HEAD')
  end

  def destroy
    FileUtils.rm_rf(repo.workdir)
  end
end
