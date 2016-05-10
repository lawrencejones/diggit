require 'diggit/services/git_helpers'
require_relative '../analysis/temporary_analysis_repo'

RSpec.describe(Diggit::Services::GitHelpers) do
  class Helpers
    include Diggit::Services::GitHelpers
    def initialize(repo)
      @repo = repo
    end
  end

  subject(:helpers) { Helpers.new(repo) }

  let(:repo) do
    TemporaryAnalysisRepo.create do |repo|
      repo.write('README.md', 'content')
      repo.commit('1')

      repo.write('another_file', 'content')
      repo.commit('2')

      repo.write('README.md', 'more content')
      repo.commit('3')
    end
  end

  describe '.rev_list' do
    subject(:log) { helpers.rev_list(commit, path) }
    let(:commit) { repo.last_commit.oid }

    context 'without path' do
      let(:path) { nil }

      it 'lists Rugged::Commits that are ancestors of given commit' do
        expect(log.map(&:message)).to eql(['3', '2', '1', 'Initial commit'])
      end
    end

    context 'with path' do
      let(:path) { 'README.md' }

      it 'lists Rugged::Commits that modified the given path' do
        expect(log.map(&:message)).to eql(['3', '1'])
      end
    end
  end
end
