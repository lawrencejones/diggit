class AddPolledToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :polled, :boolean, null: false, default: false
  end
end
