module Diggit
  module Services
    module Jwt
      JWT_ALGORITHM = 'HS256'.freeze

      def self.secret=(value)
        @secret = value
      end

      def self.encode(payload, exp)
        JWT.encode({ data: payload, exp: exp.to_i }, @secret, JWT_ALGORITHM)
      end

      def self.decode(token)
        decoded, = JWT.decode(token, @secret, true, algorithm: JWT_ALGORITHM)
        decoded
      end
    end
  end
end
