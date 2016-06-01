class PullAnalysis < ActiveRecord::Base
  belongs_to :project
  validates_presence_of :pull, :head, :base, :duration
  validates_uniqueness_of :pull, scope: %i(project_id base head)

  scope :for_project, ->(gh_path) { joins(:project).where('projects.gh_path' => gh_path) }
  scope :for_pull, ->(pull) { where(pull: pull).order(:created_at) }
  scope :with_comments, -> { where("comments::text <> '[]'") }

  def self.comment_indexes_for(gh_path, pull)
    for_project(gh_path).for_pull(pull).
      flat_map(&:comments).
      map { |comment| comment.slice('report', 'index') }
  end
end
