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

      def initialize(project, remote: project.gh_path)
        @project = project
        @remote = remote
        @repo_path = File.join(CACHE_DIR, project.gh_path)
      end

      # Yields with a Git::Base handle to the project, referencing a temporary working
      # directory that exists only within the block.
      def clone
        load_cache_repo
        with_temporary_dir do |scratch_repo_path|
          Git.clone(repo_path, scratch_repo_path)
          repo = Git.open(scratch_repo_path)
          yield(repo)
        end
      end

      private

      attr_reader :repo_path, :remote, :project

      # Cached bare git repository, within CACHE_DIR
      # If the cache doesn't exist, then this will create it, cloning the repo with the
      # projects ssh keys.
      def load_cache_repo
        FileUtils.mkdir_p(repo_path)
        info { "[#{project.gh_path}] Fetching from #{remote}..." }
        with_git_keys do
          repo = Git.init(repo_path, bare: true)
          unless repo.remotes.map(&:name).include?(remote)
            repo.add_remote(remote, "git@github.com:#{remote}")
          end
          git_output = repo.fetch(remote)
          info { git_output }
        end
      end

      # Clobber git environment to enable ssh commands to take place with the projects
      # deploy keys.
      def with_git_keys
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
