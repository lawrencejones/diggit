require 'diggit/analysis/refactor_diligence/report'
require_relative './test_repo'

RSpec.describe(Diggit::Analysis::RefactorDiligence::Report) do
  subject(:report) { described_class.new(repo, base: base, head: head) }
  let(:repo) { refactor_diligence_test_repo }

  def branch_oid(branch)
    repo.branches.find { |b| b.name == branch }.target.oid
  end

  let(:head) { branch_oid('feature') }
  let(:base) { branch_oid('master') }

  before { stub_const("#{described_class}::TIMES_INCREASED_THRESHOLD", threshold) }
  let(:threshold) { 2 }

  describe '#comments' do
    subject(:comments) { report.comments }

    def comment_for(method)
      comments.find { |c| c[:meta][:method_name][method] }
    end
    let(:socket_comment) { comment_for(/Socket::initialize/) }
    let(:master_comment) { comment_for(/Master::initialize/) }

    context 'when pull does not change ruby files' do
      let(:head) { branch_oid('non-ruby') }
      let(:base) { branch_oid('feature') }

      it { is_expected.to eql([]) }
    end

    it 'does not include methods that have not increased in size in this diff' do
      expect(master_comment).to be_nil
    end

    it 'include methods that are above threshold', :aggregate_failures do
      expect(socket_comment).to include(
        report: 'RefactorDiligence',
        message: /has increased in size the last 3 times/i,
        location: 'file.rb:8',
        meta: {
          method_name: 'Utils::Socket::initialize',
          times_increased: 3,
        }
      )
    end

    it 'tags commit shas in comment' do
      shas_in_comment = socket_comment[:message].scan(/\S{40}/)
      expect(shas_in_comment.size).to be(3)
      shas_in_comment.each { |sha| expect(repo.exists?(sha)).to be(true) }
    end

    it 'does not include methods below threshold' do
      from_uri = comments.find { |c| c[:meta][:method_name][/from_uri/] }
      expect(from_uri).to be_nil
    end
  end
end
