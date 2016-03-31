class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :github_path, null: false, limit: 126
    end

    add_index :projects, :github_path, unique: true
  end
end
