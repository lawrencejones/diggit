module Diggit
  module Github
    # Facilitates cloning of github repos with a specific ssh private key.
    class Cloner
      def initialize(ssh_private_key)
        @ssh_private_key = ssh_private_key
      end

      def clone(gh_path)
        Dir.mktmpdir('cloner') do |scratch|
          with_temporary_keyfile(@ssh_private_key) do |keyfile|
            repo = clone_with_keyfile(gh_path, keyfile,
                                      to: File.join(scratch, gh_path.split('/').last))
            yield(repo)
          end
        end
      end

      private

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
      def clone_with_keyfile(gh_path, keyfile, to:)
        pid = Process.fork do
          begin
            ENV['GIT_SSH_COMMAND'] = "ssh -i #{keyfile}"
            Git.clone("git@github.com:#{gh_path}", to)
          ensure
            Kernel.exit! # required to not screw up socket connections
          end
        end

        Process.wait(pid)
        Git.open(to)
      end
    end
  end
end
