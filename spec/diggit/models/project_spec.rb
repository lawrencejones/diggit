require 'diggit/models/project'

RSpec.describe(Project) do
  subject(:repo) { described_class.new(params) }
  let(:params) { { github_path: 'lawrencejones/diggit' } }

  context 'with missing github_path' do
    before { params[:github_path] = nil }
    it { is_expected.not_to be_valid }
  end

  context 'with invalid github_path' do
    before { params[:github_path] = 'lawrencejones' }
    it { is_expected.not_to be_valid }
  end
end
