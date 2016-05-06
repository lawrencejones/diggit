require 'que'

require_relative 'analyse_pull'
require_relative '../logger'
require_relative '../models/project'
require_relative '../models/pull_analysis'
require_relative '../github/client'

module Diggit
  module Jobs
    # Looks through all Projects that are set for polling, and enqueues AnalysePull jobs
    # for any that have un-analysed pulls.
    class PollGithub < Que::Job
      include InstanceLogger

      def run
        if polled_projects.empty?
          info { 'No projects are set to poll, doing nothing' }
          return destroy
        end

        ActiveRecord::Base.transaction do
          polled_projects.each { |project| poll(project) }
          destroy
        end
      end

      def poll(project)
        info { "Polling #{project.gh_path} for new PRs..." }
        Github.client.pulls(project.gh_path).each do |pull|
          queue_analysis(pull, project) unless pull_analysis_exists?(pull)
        end
      end

      def queue_analysis(pull, project)
        info { "Queue analysis for #{project.gh_path}/pulls/#{pull[:number]}" }
        AnalysePull.
          enqueue(project.gh_path,
                  pull[:number],
                  pull[:head][:sha],
                  pull[:base][:sha])
      end

      def pull_analysis_exists?(pull)
        PullAnalysis.
          joins(:project).
          where('projects.gh_path' => pull[:head][:repo][:full_name]).
          exists?(pull: pull[:number],
                  head: pull[:head][:sha],
                  base: pull[:base][:sha])
      end

      def polled_projects
        @polled_projects ||= Project.where(polled: true)
      end
    end
  end
end
