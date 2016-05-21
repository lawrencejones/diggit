require 'rugged'
require 'fileutils'

require_relative 'environment'
require_relative 'project_credentials'
require_relative '../system'
require_relative '../logger'

module Diggit
  module Services
    class ProjectCloner
      CACHE_DIR = File.join(System::APP_ROOT, 'tmp', 'project_cache').freeze
      GITHUB_PULLS_REFSPEC = '+refs/pull/*/head:refs/remotes/origin/pull/*'.freeze
      LOCK_FILE = 'config'.freeze # lock on the git config file

      include InstanceLogger

      def initialize(project, logger_prefix: nil)
        @project = project
        @repo_path = File.join(CACHE_DIR, project.gh_path)
        @credentials = ProjectCredentials.new(project)

        @logger_prefix = logger_prefix unless logger_prefix.nil?
        @repo ||= create_repo unless File.directory?(repo_path)
        @repo ||= Rugged::Repository.new(repo_path)
      end

      # Yields with a Rugged::Repository handle to the project, referencing a temporary
      # working directory that exists only within the block.
      def clone
        fetch
        with_temporary_dir do |scratch_repo_path|
          yield(Rugged::Repository.clone_at(repo_path, scratch_repo_path))
        end
      end

      private

      attr_reader :repo, :repo_path, :project, :credentials

      # Initializes a bare repo with an origin remote configured to fetch both normal and
      # pull refs.
      def create_repo
        Rugged::Repository.init_at(repo_path, :bare).tap do |repo|
          repo.remotes.create('origin', "git@github.com:#{project.gh_path}")
          repo.remotes.add_fetch_refspec('origin', GITHUB_PULLS_REFSPEC)
        end
      end

      # Fetches from origin using ssh keys
      def fetch
        credentials.with_keyfiles do |keyfiles|
          ssh_creds = Rugged::Credentials::SshKey.
            new(keyfiles.merge(username: 'git'))
          synchronise do
            info { 'Fetching origin...' }
            repo.fetch('origin', credentials: ssh_creds)
          end
        end
      end

      # Process lock on the project cache config file. This prevents multiple processes
      # from fetching into the cache at the same time.
      def synchronise
        info { "Acquiring lock on .git/#{LOCK_FILE}..." }
        lock_file = File.open(File.join(repo_path, LOCK_FILE), File::CREAT)
        lock_file.flock(File::LOCK_EX)
        yield.tap do
          info { 'Releasing lock...' }
          lock_file.flock(File::LOCK_UN)
        end
      end

      # Temporary directories for this class
      def with_temporary_dir
        Dir.mktmpdir('project-cloner') do |scratch|
          yield(File.join(scratch, project.gh_path.split('/').last))
        end
      end
    end
  end
end
