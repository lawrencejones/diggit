require 'octokit'
require 'github/repo'

RSpec.describe(Github::Repo) do
  subject(:repo) { described_class.new(github_path) }
  before { allow(Github).to receive(:client).and_return(double(:client).as_null_object) }

  let(:github_path) { 'lawrencejones/diggit' }
  let(:webhook_endpoint) { 'https://diggit.io/github/webhooks' }

  context 'when repo does not exist' do
    before do
      allow(Github.client).
        to receive(:repo).
        with(github_path).
        and_raise(Octokit::NotFound)
    end

    it 'raises error' do
      expect { repo }.to raise_error(/Could not access repo/i)
    end
  end

  describe '#webhook_already_setup?' do
    subject { repo.webhook_already_setup?(webhook_endpoint) }
    before do
      allow(Github.client).
        to receive(:hooks).
        with(github_path).
        and_return(webhooks)
    end

    context 'when webhook with same endpoint is already present' do
      let(:webhooks) { [{ config: { url: webhook_endpoint } }] }
      it { is_expected.to be(true) }
    end

    context 'otherwise' do
      let(:webhooks) { [{ config: { url: 'https://another-endpoint.com/webhooks' } }] }
      it { is_expected.to be(false) }
    end
  end
end
