class PullAnalysis < ActiveRecord::Base
  belongs_to :project
  validates_presence_of :pull, :head, :base
  validates_uniqueness_of :pull, scope: %i(project_id base head)

  scope :for_project, ->(gh_path) { joins(:project).where('projects.gh_path' => gh_path) }
end
