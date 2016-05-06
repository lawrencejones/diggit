class AddPushedToGithubToPullAnalysis < ActiveRecord::Migration
  def up
    add_column :pull_analyses, :pushed_to_github, :boolean, null: false, default: false
    execute <<-SQL
    UPDATE pull_analyses
       SET pushed_to_github=True;
    SQL
  end

  def down
    remove_column :pull_analyses, :pushed_to_github, :boolean
  end
end
