require 'hamster/hash'

require_relative 'refactor_diligence/report'
require_relative 'complexity/report'
require_relative '../logger'

module Diggit
  module Analysis
    class Pipeline
      REPORTERS = [RefactorDiligence::Report, Complexity::Report].freeze
      class BadGitHistory < StandardError; end
      include InstanceLogger

      def initialize(repo, head:, base:)
        @repo = repo
        @head = head
        @base = base

        verify_refs!
        repo.reset(head, :hard)
      end

      def aggregate_comments
        REPORTERS.map do |report|
          info { "[#{repo_label}] #{report}..." }
          repo.reset(head, :hard)
          report.new(repo, base: base, head: head).comments
        end.flatten
      end

      private

      attr_reader :repo, :head, :base

      def verify_refs!
        raise BadGitHistory, "Missing base commit #{base}" unless repo.exists?(base)
        raise BadGitHistory, "Missing head commit #{head}" unless repo.exists?(head)
      end

      def repo_label
        File.basename(repo.workdir)
      end
    end
  end
end
