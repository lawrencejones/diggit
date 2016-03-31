class Project < ActiveRecord::Base
  validates_presence_of :github_path
  validates_format_of :github_path, with: %r{\A[^\/]+\/[^\/]+\z}
end
