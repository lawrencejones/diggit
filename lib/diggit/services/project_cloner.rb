require 'git'
require 'fileutils'

require_relative 'environment'
require_relative '../system'
require_relative '../logger'

module Diggit
  module Services
    class ProjectCloner
      CACHE_DIR = File.join(System::APP_ROOT, 'tmp', 'project_cache').freeze
      include InstanceLogger

      def initialize(project)
        @project = project
        @repo_path = File.join(CACHE_DIR, project.gh_path)
      end

      # Yields with a Git::Base handle to the project, referencing a temporary working
      # directory that exists only within the block.
      def clone
        load_cache_repo
        with_temporary_dir do |scratch_repo_path|
          Git.clone(repo_path, scratch_repo_path)
          g = Git.open(scratch_repo_path)
          yield(g)
        end
      end

      private

      attr_reader :repo_path, :project

      # Cached bare git repository, within CACHE_DIR
      # If the cache doesn't exist, then this will create it, cloning the repo with the
      # projects ssh keys.
      def load_cache_repo
        FileUtils.mkdir_p(repo_path)
        with_git_keys do
          project_git_dir = File.join(repo_path, '.git')
          create_cache_repo unless File.directory?(project_git_dir)
          Git.bare(project_git_dir).tap { |g| logged_fetch(g) }
        end
      end

      # Fetch from origin of the given git handle
      def logged_fetch(g)
        info { "[#{project.gh_path}] Fetching origin..." }
        git_output = g.fetch('origin')
        info { git_output } if git_output.present?
      end

      # Initializes a bare repo with an origin remote configured to fetch both normal and
      # pull refs.
      def create_cache_repo
        Git.init(repo_path, bare: true).tap do
          config_file = File.join(repo_path, '.git', 'config')
          open(config_file, 'a') do |f|
            f << %(
            [remote "origin"]
            \turl = git@github.com:#{project.gh_path}
            \tfetch = +refs/heads/*:refs/remotes/origin/*
            \tfetch = +refs/pull/*/head:refs/remotes/origin/pull/*)
          end
        end
      end

      # Clobber git environment to enable ssh commands to take place with the projects
      # deploy keys.
      def with_git_keys
        return yield unless project.keys?

        with_temporary_keyfile do |keyfile|
          Environment.with_temporary_env('GIT_SSH_COMMAND' => "ssh -i #{keyfile}") do
            yield # run block with env
          end
        end
      end

      # Securely write an ephemeral keyfile, removing the file once done.
      def with_temporary_keyfile
        keyfile = Tempfile.open('private-key')
        File.write(keyfile, project.ssh_private_key || '')
        yield(keyfile.path)
      ensure
        keyfile.close
        keyfile.unlink
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
