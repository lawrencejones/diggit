require 'nokogiri'
require 'diggit/services/mailer'

RSpec.describe(Diggit::Services::Mailer) do
  class MockMailer
    include Diggit::Services::Mailer

    def say(word)
      word
    end
  end
  subject(:mailer) { MockMailer.new }
  before { stub_const("#{described_class}::DELIVERY_METHOD", [:test]) }

  describe 'including' do
    it 'defines class methods' do
      expect(MockMailer.singleton_methods).to include(:html_body, :deliver_to, :subject)
    end
  end

  describe '.render' do
    subject(:html) { mailer.render }
    before do
      stub_const "#{described_class}::LAYOUT", <<-ERB
      <html><%= yield %></html>
      ERB
      MockMailer.html_body <<-ERB
      <p><%= say('hello') %></p>
      ERB
    end

    it 'yields erb processed @@html_body into parent template' do
      expect(Nokogiri.parse(html).css('p').first.content).to eql('hello')
    end

    it 'returns result of Roadie css inlining' do
      allow(Roadie::Document).to receive(:new).
        and_return(instance_double(Roadie::Document, transform: 'BAZINGA'))
      expect(html).to eql('BAZINGA')
    end
  end

  describe '.send!' do
    subject(:mail) { mailer.send! }
    before do
      MockMailer.deliver_to 'default@address.com'
      MockMailer.subject 'Default Subject'
      MockMailer.html_body '<p>PEW PEW</p>'
    end

    it 'sets mail fields to class defaults' do
      expect(mail.to).to include('default@address.com')
      expect(mail.subject).to eql('Default Subject')
      expect(mail.html_part.body).to match(/PEW PEW/)
    end

    context 'with instance specific settings' do
      before { mailer.deliver_to 'lucky-guy@gmail.com' }

      it 'uses specific setting instead' do
        expect(mail.to).to include('lucky-guy@gmail.com')
      end
    end
  end
end
