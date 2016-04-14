require 'diggit/analysis/refactor_diligence/report'
require_relative './test_repo'

RSpec.describe(Diggit::Analysis::RefactorDiligence::Report) do
  subject(:report) { described_class.new(repo, files_changed: files_changed) }
  let(:repo) { refactor_diligence_test_repo }

  let(:head) { repo.log.first.sha }
  let(:base) { repo.log.last.sha }
  let(:files_changed) { repo.diff(base, head).stats.fetch(:files).keys }

  before { stub_const("#{described_class}::TIMES_INCREASED_THRESHOLD", threshold) }
  let(:threshold) { 2 }

  describe '#comments' do
    subject(:comments) { report.comments }

    it 'include methods that are above threshold', :aggregate_failures do
      socket_comment = comments.find { |c| c[:meta][:method_name][/Socket::initialize/] }

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

    it 'does not include methods below threshold' do
      from_uri = comments.find { |c| c[:meta][:method_name][/from_uri/] }
      expect(from_uri).to be_nil
    end
  end
end
