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
      socket_init = comments.find { |c| c[:meta][:method_name][/Socket::initialize/] }
      meta = socket_init.fetch(:meta)

      expect(socket_init).not_to be_nil
      expect(socket_init).to include(report: 'RefactorDiligence')
      expect(socket_init).to include(message: /has increased in size the last 3 times/i)
      expect(socket_init).to include(location: 'file.rb:8')

      expect(meta).not_to be_nil
      expect(meta).to include(times_increased: 3)
      expect(meta).to include(method_name: 'Utils::Socket::initialize')
    end

    it 'does not include methods below threshold' do
      from_uri = comments.find { |c| c[:meta][:method_name][/from_uri/] }
      expect(from_uri).to be_nil
    end
  end
end
