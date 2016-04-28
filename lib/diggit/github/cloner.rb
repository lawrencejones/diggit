module Diggit
  module Github
    # Facilitates cloning of github repos into temporary workspaces
    class Cloner
      def initialize(gh_path)
        @gh_path = gh_path
      end

      def clone
        with_temporary_dir do |temp_dir|
          Git.clone("https://github.com/#{@gh_path}.git", temp_dir)
          yield(Git.open(temp_dir))
        end
      end

      def clone_with_key(ssh_private_key)
        with_temporary_dir do |temp_dir|
          with_temporary_keyfile(ssh_private_key) do |keyfile|
            yield clone_with_keyfile(keyfile, to: temp_dir)
          end
        end
      end

      private

      def with_temporary_dir
        Dir.mktmpdir('cloner') do |scratch|
          yield(File.join(scratch, @gh_path.split('/').last))
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
      def clone_with_keyfile(keyfile, to:)
        pid = Process.fork do
          begin
            ENV['GIT_SSH_COMMAND'] = "ssh -i #{keyfile}"
            Git.clone("git@github.com:#{@gh_path}", to)
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
