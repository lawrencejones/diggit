require 'diggit/services/cache'

RSpec.describe(Diggit::Services::Cache) do
  before do
    allow(cache).to receive(:conn).and_return(conn)
    allow(cache).to receive(:prefix).and_return('diggit')
  end
  let(:cache) { Diggit::Services::Cache }
  let(:conn) { instance_double(Redis) }

  describe '.store' do
    it 'prefixes key with `diggit:`' do
      expect(conn).to receive(:set).with('diggit:key', anything)
      cache.store('key', 'value')
    end

    it 'serializes value before storing' do
      expect(conn).to receive(:set).with(anything, '{"a":5}')
      cache.store('key', 'a' => 5)
    end
  end

  describe '.get' do
    it 'retrieves and deserializes value from prefixed key' do
      allow(conn).to receive(:get).with('diggit:key').and_return('{"a": 5}')
      expect(cache.get('key')).to eql('a' => 5)
    end
  end

  describe '.delete' do
    it 'prefixes key and deletes' do
      expect(conn).to receive(:del).with('diggit:key')
      cache.delete('key')
    end
  end
end
