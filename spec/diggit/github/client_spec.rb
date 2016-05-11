require 'diggit/github/client'

RSpec.describe(Diggit::Github) do
  let(:github) { described_class }

  describe '.client_for' do
    context 'project without gh_token' do
      let(:project) { FactoryGirl.create(:project) }

      it 'gives Diggit::Github.client' do
        expect(github.client_for(project)).to be(Diggit::Github.client)
      end
    end

    context 'project with gh_token' do
      let(:project) { FactoryGirl.create(:project, :gh_token) }

      it 'initialises new client with token' do
        expect(Octokit::Client).
          to receive(:new).
          with(access_token: project.gh_token).
          and_call_original
        expect(github.client_for(project)).to be_instance_of(Octokit::Client)
      end
    end
  end
end
