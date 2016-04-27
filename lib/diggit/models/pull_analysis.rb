class PullAnalysis < ActiveRecord::Base
  belongs_to :project
  validates_presence_of :pull
  validates_uniqueness_of :pull, scope: :project_id

  scope :for_project, ->(gh_path) { joins(:project).where('projects.gh_path' => gh_path) }
end
