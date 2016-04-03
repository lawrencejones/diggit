require 'active_record'
require_relative 'lib/diggit/system'
load 'active_record/railties/databases.rake'

seed_loader = Class.new do
  def load_seed
    load "#{ActiveRecord::Tasks::DatabaseTasks.db_dir}/seeds.rb"
  end
end

ActiveRecord::Tasks::DatabaseTasks.tap do |config|
  config.root = Rake.application.original_dir
  config.env = ENV['RACK_ENV'] || 'development'
  config.db_dir = 'db'
  config.migrations_paths = ['db/migrate']
  config.fixtures_path = 'spec/fixtures'
  config.seed_loader = seed_loader.new
  config.database_configuration = YAML.load_file('config/database.yml')
end

# define Rails' tasks as no-op
Rake::Task.define_task('db:environment')
Rake::Task['db:test:deprecated'].clear if Rake::Task.task_defined?('db:test:deprecated')

namespace :db do
  task :que_setup do
    Diggit::System.init
    Que.migrate!
  end

  task :load_config do
    Diggit::System.init
  end

  desc 'Create a migration (parameters: NAME, VERSION)'
  task :create_migration do
    unless ENV['NAME']
      puts 'No NAME specified. Example: `rake db:create_migration NAME=create_users`'
      exit
    end

    name    = ENV['NAME']
    version = ENV['VERSION'] || Time.now.utc.strftime('%Y%m%d%H%M%S')

    ActiveRecord::Migrator.migrations_paths.each do |directory|
      next unless File.exist?(directory)
      migration_files = Pathname(directory).children
      duplicate = migration_files.find { |path| path.basename.to_s.include?(name) }
      unless duplicate.nil?
        puts "Another migration is already named \"#{name}\": #{duplicate}."
        exit
      end
    end

    filename = "#{version}_#{name}.rb"
    dirname  = ActiveRecord::Migrator.migrations_path
    path     = File.join(dirname, filename)

    FileUtils.mkdir_p(dirname)
    File.write path, <<-MIGRATION.strip_heredoc
      class #{name.camelize} < ActiveRecord::Migration
        def change
        end
      end
    MIGRATION

    puts path
  end
end
