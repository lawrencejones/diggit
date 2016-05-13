require 'que'
require 'prius'
require 'active_support/core_ext/module'

require_relative 'cron_job'
require_relative '../services/mailer'
require_relative '../logger'

module Diggit
  module Jobs
    class DailyAnalysisSummary < CronJob
      include InstanceLogger
      include Services::Mailer

      deliver_to 'lawrjone@gmail.com'
      subject '[diggit] Daily Analysis Summary'

      html_body <<-ERB
      <table id="analysis-content">
        <tr>
          <td>
            <h1>Daily Analysis Summary</h1>
            <p class="summary">
              <b><%= new_analyses.count %></b> new Pull Analyses created in the last 24
              hours, pushing <b><%= new_comments.count %></b> new comments to GitHub!
            </p>

            <h2>Breakdown</h2>
            <table>
              <tbody>
                <% for project in projects_with_new_analyses %>
                  <% analyses = new_analyses_for(project) %>
                  <% for analysis, i in analyses.each_with_index %>
                    <tr>

                      <% if i == 0 %>
                        <td rowspan="<%= analyses.count %>" valign="middle">
                          <a class="project" href="<%= link_for_project(project) %>">
                            <%= project.gh_path %>
                          </a>
                        </td>
                      <% end %>

                      <td>
                        <a href="<%= link_for_pull(analysis) %>">
                          <%= analysis.pull %>
                        </a>
                      </td>

                      <td><%= analysis.comments.size %></td>

                    </tr>
                  <% end %>

                  <tr>
                    <td colspan="3"
                        style="padding-top: 5px; border-bottom: 1px solid #ddd">
                    </td>
                  </tr>
                  <tr><td colspan="3" style="padding-top: 5px"></td></tr>
                <% end %>
              </tbody>
            </table>
          </td>
        </tr>
      </table>
      ERB

      SCHEDULE_AT = ['20:00'].freeze

      def run
        info { 'Generating summary...' }
        send!
        info { 'Sent!' }
      end

      private

      def link_for_pull(analysis)
        "#{link_for_project(analysis.project)}/pull/#{analysis.pull}"
      end

      def link_for_project(project)
        "https://github.com/#{project.gh_path}"
      end

      def new_analyses_for(project)
        PullAnalysis.where(project: project, created_at: time_range)
      end

      def projects_with_new_analyses
        @projects_with_new_analyses ||= Project.
          where(id: new_analyses.pluck(:project_id).uniq)
      end

      def new_analyses
        @new_analyses ||= PullAnalysis.where(created_at: time_range)
      end

      def new_comments
        @new_comments ||= new_analyses.pluck(:comments).flatten
      end
    end
  end
end
