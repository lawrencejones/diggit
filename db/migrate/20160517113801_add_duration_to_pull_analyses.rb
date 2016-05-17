class AddDurationToPullAnalyses < ActiveRecord::Migration
  def change
    add_column :pull_analyses, :duration, :decimal, null: false, default: 0.0
  end
end
