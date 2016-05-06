class AddBaseHeadToPullAnalysis < ActiveRecord::Migration
  def change
    add_column :pull_analyses, :base, :text, limit: 40
    add_column :pull_analyses, :head, :text, limit: 40
  end
end
