require 'digest'

module Diggit
  module Services
    module Secure
      module ActiveRecordHelpers
        def encrypted_field(field, iv:)
          define_method(field) do
            encrypted_payload = send(:"encrypted_#{field}")
            return nil if encrypted_payload.nil?

            Secure.decode(encrypted_payload, send(iv))
          end

          define_method(:"#{field}=") do |value|
            encrypted, initialization_vector = Secure.encode(value)
            send(:"encrypted_#{field}=", encrypted)
            send(:"#{iv}=", initialization_vector)
          end
        end
      end

      def self.secret=(value)
        @secret = Digest::SHA2.digest(value)
      end

      def self.create_cipher(mode)
        OpenSSL::Cipher::AES.new(256, :CBC).
          tap(&mode).
          tap { |c| c.key = @secret }
      end

      def self.encode(payload)
        cipher = create_cipher(:encrypt)
        iv = cipher.random_iv

        [cipher.update(payload) + cipher.final, iv]
      end

      def self.decode(encrypted, iv)
        decipher = create_cipher(:decrypt)
        decipher.iv = iv

        decipher.update(encrypted) + decipher.final
      end
    end
  end
end
