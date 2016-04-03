class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :gh_path, null: false, limit: 126
    end

    add_index :projects, :gh_path, unique: true
  end
end
