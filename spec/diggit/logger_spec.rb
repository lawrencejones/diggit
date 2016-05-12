require 'diggit/logger'

RSpec.describe(Diggit::InstanceLogger) do
  class Mock
    include Diggit::InstanceLogger
  end
  subject(:instance) { Mock.new }
  let(:message) { 'how you doin' }

  context 'with no logger_prefix' do
    it 'calls Diggit.logger.method with block that yields message' do
      expect(Diggit.logger).to receive(:info) do |&block|
        expect(block.call).to eql(message)
      end
      instance.info { message }
    end
  end

  context 'with logger_prefix' do
    before { instance.logger_prefix = prefix }
    let(:prefix) { '[prefix]' }

    it 'calls Diggit.logger.method with block that yields prefixed method' do
      expect(Diggit.logger).to receive(:info) do |&block|
        expect(block.call).to eql('[prefix] how you doin')
      end
      instance.info { message }
    end
  end
end
