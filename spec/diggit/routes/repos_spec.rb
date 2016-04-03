require 'octokit'
require 'active_support'

require 'diggit/models/project'
require 'diggit/routes/repos'

RSpec.describe(Diggit::Routes::Repos::Index) do
  subject(:instance) { described_class.new(context, null_middleware, {}) }

  let(:context) { { gh_client: gh_client } }

  let(:gh_client) { instance_double(Octokit::Client) }
  let(:repos_fixture) { load_json_fixture('github_client/repos.json') }
  before do
    allow(gh_client).
      to receive(:repos).
      and_return(repos_fixture.map(&:deep_symbolize_keys))
  end

  it { is_expected.to respond_with_status(200) }
  it { is_expected.to respond_with_json({
    'repos' => [
      { 'gh_path' => 'lawrencejones/librespot',
        'private' => false,
        'project_id' => nil },
      { 'gh_path' => 'lawrencejones/BearwavesWebsite',
        'private' => false,
        'project_id' => nil },
      { 'gh_path' => 'lawrencejones/LiveHack',
        'private' => false,
        'project_id' => nil },
    ]
  }) }

  context 'when a library is being watched' do
    let!(:librespot) { Project.create(gh_path: 'lawrencejones/librespot') }
    let(:json_response) { JSON.parse(instance.call[2].join('')) }

    it 'serializes project id' do
      serialized_librespot = json_response['repos'].
        find { |repo| repo['gh_path'] == librespot.gh_path }
      expect(serialized_librespot).to include('project_id' => librespot.id)
    end
  end
end
