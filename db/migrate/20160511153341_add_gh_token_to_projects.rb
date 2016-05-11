class AddGhTokenToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :encrypted_gh_token, :binary
    add_column :projects, :gh_token_initialization_vector, :binary
  end
end
