class Project < ActiveRecord::Base
  validates_presence_of :gh_path
  validates_format_of :gh_path, with: %r{\A[^\/]+\/[^\/]+\z}
end
