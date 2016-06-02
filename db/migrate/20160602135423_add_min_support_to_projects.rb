class AddMinSupportToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :min_support, :integer, null: false, default: 0
  end
end
