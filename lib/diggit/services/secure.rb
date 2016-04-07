require 'digest'

module Diggit
  module Services
    module Secure
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
