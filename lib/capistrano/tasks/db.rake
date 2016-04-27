namespace :db do
  desc 'Runs rake db:migrate if migrations are set'
  task :migrate do
    on roles(:app) do
      info '[deploy:migrate] Checking changes in /db/migrate'
      if test("diff -q #{release_path}/db/migrate #{current_path}/db/migrate")
        info '[deploy:migrate] Skip `deploy:migrate` (nothing changed in db/migrate)'
      else
        info '[deploy:migrate] Run `rake db:migrate`'
        invoke :'deploy:migrating'
      end
    end
  end

  desc 'Runs rake db:migrate'
  task :migrating do
    on roles(:app) do
      within release_path do
        with rack_env: fetch(:stage) do
          execute :rake, 'db:migrate'
        end
      end
    end
  end

  after 'bundler:install', 'db:migrate'
end
