require 'active_support/core_ext/module'
require_relative '../system'

module Diggit
  module Services
    class ProjectCredentials
      DEFAULT_KEYFILES = {
        privatekey: File.join(System::APP_ROOT, 'keys', 'id_rsa'),
        publickey: File.join(System::APP_ROOT, 'keys', 'id_rsa.pub'),
      }.freeze

      def initialize(project)
        @project = project
      end

      def with_keyfiles(&block)
        return yield(DEFAULT_KEYFILES) unless project.keys?
        with_ephemeral_keyfiles(&block)
      end

      private

      attr_reader :project
      delegate :ssh_private_key, :ssh_public_key, to: :project

      # Generates ephemeral keyfiles containing the projects private/public keys
      def with_ephemeral_keyfiles
        private_keyfile = write_tempfile(ssh_private_key)
        public_keyfile = write_tempfile(ssh_public_key)

        keyfiles = [private_keyfile, public_keyfile]
        yield(privatekey: private_keyfile.path, publickey: public_keyfile.path)
      ensure
        keyfiles.each(&:close).each(&:unlink)
      end

      def write_tempfile(contents)
        Tempfile.open('key').tap do |file|
          file.write(contents)
          file.rewind
        end
      end
    end
  end
end
