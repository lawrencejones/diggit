require 'que'

require_relative 'repeat_job'
require_relative 'analyse_pull'
require_relative '../logger'
require_relative '../models/project'
require_relative '../models/pull_analysis'
require_relative '../github/client'

module Diggit
  module Jobs
    # Looks through all Projects that are set for polling, and enqueues AnalysePull jobs
    # for any that have un-analysed pulls.
    #
    # Will continually queue the next job, with the POLLING_INTERVAL delay.
    class PollGithub < RepeatJob
      INTERVAL = 60 # seconds
      include InstanceLogger

      def run
        if polled_projects.empty?
          info { 'No projects are set to poll, doing nothing' }
          return destroy
        end

        polled_projects.each { |project| poll(project) }
        destroy
      end

      def poll(project)
        info { "[#{project.gh_path}] Polling for new PRs..." }
        Github.client_for(project).pulls(project.gh_path, per_page: 100).
          reject { |pull| pull_analysis_exists?(pull) }.
          reject { |pull| analysis_queued?(pull) }.
          each   { |pull| queue_analysis(pull, project) }
      end

      def queue_analysis(pull, project)
        info { "[#{project.gh_path}] Queue analysis for pull #{pull[:number]}" }
        AnalysePull.
          enqueue(project.gh_path,
                  pull[:number],
                  pull[:head][:sha],
                  pull[:base][:sha])
      end

      def analysis_queued?(pull)
        analysis_jobs = Que.execute <<-SQL
        SELECT args
          FROM que_jobs
         WHERE job_class='Diggit::Jobs::AnalysePull';
        SQL

        job_args = job_args_for(pull)
        analysis_jobs.any? { |job| job['args'] == job_args }
      end

      def job_args_for(pull)
        [pull[:base][:repo][:full_name], pull[:number],
         pull[:head][:sha], pull[:base][:sha]]
      end

      def pull_analysis_exists?(pull)
        PullAnalysis.
          joins(:project).
          where('projects.gh_path' => pull[:base][:repo][:full_name]).
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
