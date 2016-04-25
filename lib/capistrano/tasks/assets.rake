namespace :assets do
  desc 'Compile bundle'
  task :bundle do
    on roles(:app) do
      within(release_path) do
        execute :npm, 'run bundle'
      end
    end
  end

  after 'npm:install', 'assets:bundle'
end
