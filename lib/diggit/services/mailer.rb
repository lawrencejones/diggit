require 'mail'
require 'ostruct'
require 'roadie'

module Diggit
  module Services
    module Mailer
      FROM = 'lawrjone@gmail.com'.freeze
      LAYOUT = File.read(File.expand_path('../mailer.html.erb', __FILE__))
      DELIVERY_METHOD = [
        :smtp,
        address: 'smtp.gmail.com',
        port: 465,
        user_name: 'lawrjone@gmail.com',
        password: Prius.get(:diggit_email_password),
        ssl: true, tls: true,
        enable_starttls_auth: true,
        authentication: 'plain',
      ].freeze

      # This allows defining of mail variables on the mailer class statically, or inside
      # the mailer instance as ivars.
      #
      # Example...
      #
      #   class MockMailer
      #     include Diggit::Services::Mailer
      #     deliver_to 'default@address.com'
      #
      #     def initialize(id)
      #       person = Person.find(id)
      #       deliver_to(person.email) unless person.use_default_email?
      #     end
      #   end
      #
      MAIL_METHODS = %i(deliver_to subject html_body).freeze
      MAIL_METHODS.each do |method|
        define_method(method) do |value = nil|
          if value.nil?
            ivar = instance_variable_get(:"@#{method}")
            cvar = self.class.class_variable_get(:"@@#{method}")
            return ivar || cvar
          end

          instance_variable_set(:"@#{method}", value)
        end
      end

      module ClassMethods
        MAIL_METHODS.each do |method|
          define_method(method) do |value|
            class_variable_set(:"@@#{method}", value)
          end
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def send!
        Mail.new.tap do |mail|
          mail.from = FROM
          mail.to = deliver_to
          mail.subject = subject
          mail.html_part = render
          mail.html_part.content_type = 'text/html; charset=UTF-8'
          mail.delivery_method(*DELIVERY_METHOD)
          mail.charset = 'UTF-8'
          mail.content_transfer_encoding = '8bit'
        end.tap(&:deliver!)
      end

      def render
        fail('No html body!') if html_body.nil?

        rendered_body = ERB.new(html_body).result(binding)
        rendered_html = ERB.new(LAYOUT).result(binding_with_block { rendered_body })

        Roadie::Document.new(rendered_html).transform
      end

      private

      def binding_with_block
        binding
      end
    end
  end
end
