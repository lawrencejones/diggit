class AddReportersToPullAnalyses < ActiveRecord::Migration
  def up
    add_column :pull_analyses, :reporters, :text, array: true, default: []
    execute <<-SQL
    UPDATE pull_analyses
       SET reporters = ARRAY['RefactorDiligence']
     WHERE created_at < TIMESTAMP '2016-05-03 13:04:58 GMT'; /* Complexity deployed */

    UPDATE pull_analyses
       SET reporters = ARRAY['RefactorDiligence', 'Complexity']
     WHERE created_at > TIMESTAMP '2016-05-03 13:04:58 GMT'
       AND created_at < TIMESTAMP '2016-05-20 19:10:00 GMT'; /* ChangePattern deployed */

    UPDATE pull_analyses
       SET reporters = ARRAY['RefactorDiligence', 'Complexity', 'ChangePatterns']
     WHERE created_at > TIMESTAMP '2016-05-20 19:10:00 GMT'; /* Post-ChangePattern deploy */
    SQL
  end

  def down
    remove_column :pull_analyses, :reporters, :text, array: true
  end
end
