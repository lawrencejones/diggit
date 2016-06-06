require 'rugged'
require 'fileutils'

class TemporaryAnalysisRepo
  @repos = []

  def self.create(&block)
    new.tap do |repo|
      repo.commit('Initial commit')
      block.call(repo)
    end.rugged
  end

  def self.clean!
    @repos.map(&:destroy)
  end

  def self.schedule_for_removal(repo)
    @repos << repo
    @repos.uniq! { |r| r.rugged.workdir }
  end

  def initialize(base = Dir.mktmpdir)
    @rugged = Rugged::Repository.init_at(base)
    self.class.schedule_for_removal(self)
  end

  attr_reader :rugged

  def branch(branch)
    rugged.branches.create(branch, 'HEAD')
    rugged.checkout(branch)
  end

  def write(path, contents)
    rugged.index.tap do |index|
      filepath = File.join(rugged.workdir, path)
      FileUtils.mkdir_p(File.dirname(filepath))
      File.write(filepath, contents)
      index.add(path: path, oid: Rugged::Blob.from_workdir(rugged, path), mode: 0100644)
    end
  end

  def rm(path)
    rugged.index.tap do |index|
      File.unlink(File.join(rugged.workdir, path))
      index.remove(path)
    end
  end

  def commit(message, time: Time.zone.now)
    commit_tree = rugged.index.write_tree(rugged)
    rugged.index.write

    # rubocop:disable Rails/Date
    person = { email: 'git@test.com', name: 'Test', time: time.to_time }
    # rubocop:enable Rails/Date

    Rugged::Commit.
      create(rugged,
             message: message,
             tree: commit_tree,
             author: person, committer: person,
             parents: rugged.empty? ? [] : [rugged.head.target].compact,
             update_ref: 'HEAD')
  end

  def destroy
    FileUtils.rm_rf(rugged.workdir)
  end
end
