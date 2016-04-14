require 'coach'
require_relative '../jobs/analyse_project'
require_relative '../models/project'

module Diggit
  module Routes
    module GithubWebhooks
      class Create < Coach::Middleware
        def call
          project = find_project

          return response(404, 'not_found') if project.nil?
          return response(200, 'not_watched') unless project.watch
          return response(200, 'not_open_action') unless pr_action == 'opened'

          Jobs::AnalyseProject.
            enqueue(project.id, params['number'],
                    head: params['pull_request']['head']['sha'],
                    base: params['pull_request']['base']['sha'])

          response(200, 'analysis_queued')
        end

        private

        def response(status, message)
          [status, {}, [{ message: "project_#{message}" }.to_json]]
        end

        def find_project
          Project.find_by(gh_path: params['repository']['full_name'])
        end

        def pr_action
          params.fetch('action')
        end
      end
    end
  end
end
