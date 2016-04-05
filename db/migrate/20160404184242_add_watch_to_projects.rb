class AddWatchToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :watch, :boolean, default: true
  end
end
