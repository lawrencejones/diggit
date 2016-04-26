class CreatePullAnalysis < ActiveRecord::Migration
  def change
    create_table :pull_analyses do |t|
      t.belongs_to :project, index: true
      t.integer :pull, null: false
      t.json :comments, default: [], null: false
      t.timestamps null: false
    end

    add_foreign_key :pull_analyses, :projects
  end
end
