class MakeBaseHeadNonNullOnPullAnalysis < ActiveRecord::Migration
  def change
    change_column_null :pull_analyses, :base, false
    change_column_null :pull_analyses, :head, false

    add_index :pull_analyses, %i(project_id pull base head), unique: true
  end
end
