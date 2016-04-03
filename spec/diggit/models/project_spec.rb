require 'diggit/models/project'

RSpec.describe(Project) do
  subject(:repo) { described_class.new(params) }
  let(:params) { { gh_path: 'lawrencejones/diggit' } }

  context 'with missing gh_path' do
    before { params[:gh_path] = nil }
    it { is_expected.not_to be_valid }
  end

  context 'with invalid gh_path' do
    before { params[:gh_path] = 'lawrencejones' }
    it { is_expected.not_to be_valid }
  end
end
