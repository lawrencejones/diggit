class AddSilentToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :silent, :boolean, null: false, default: false
  end
end
