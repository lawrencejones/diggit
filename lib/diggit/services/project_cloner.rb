require 'git'
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

      include InstanceLogger

      def initialize(project)
        @project = project
        @repo_path = File.join(CACHE_DIR, project.gh_path)
        @credentials = ProjectCredentials.new(project)

        @repo ||= create_repo unless File.directory?(repo_path)
        @repo ||= Rugged::Repository.new(repo_path)
      end

      # Yields with a Git::Base handle to the project, referencing a temporary working
      # directory that exists only within the block.
      def clone
        fetch
        with_temporary_dir do |scratch_repo_path|
          Rugged::Repository.clone_at(repo_path, scratch_repo_path)
          yield(Git.open(scratch_repo_path))
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
          info { "[#{project.gh_path}] Fetching origin..." }
          repo.fetch('origin', credentials: ssh_creds)
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
