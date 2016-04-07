require 'que'
require 'git'
require 'tempfile'

require_relative '../models/project'

module Diggit
  module Jobs
    class AnalyseProject < Que::Job
      def run(project_id, head:, base:)
        project = Project.find(project_id)
        return unless project.watch

        Que.log(message: "Cloning #{project.gh_path}...")
        clone(project) do |repo|
          Que.log(message: "Successfully cloned #{project.gh_path}##{repo.branch.name}")
          Que.log(message: "Starting analysis of #{project.gh_path} for #{base}..#{head}")
          # TODO: Kickoff analysis here
        end
      end

      def clone(project)
        Dir.mktmpdir('analysis') do |scratch|
          with_temporary_keyfile(project.ssh_private_key) do |keyfile|
            repo = clone_with_keyfile(project, keyfile,
                                      to: File.join(scratch, project.repo))
            yield(repo)
          end
        end
      end

      def with_temporary_keyfile(key)
        keyfile = Tempfile.open('private-key')
        File.write(keyfile, key)
        yield(keyfile.path)
      ensure
        keyfile.close
        keyfile.unlink
      end

      # Runs a git clone with a specified private key file. Git clone has to be run in
      # subprocess as we are required to modify the environment.
      def clone_with_keyfile(project, keyfile, to:)
        pid = Process.fork do
          ENV['GIT_SSH_COMMAND'] = "ssh -i #{keyfile}"
          Git.clone("git@github.com:#{project.gh_path}", to)
        end

        Process.wait(pid)
        Git.open(to)
      end
    end
  end
end
