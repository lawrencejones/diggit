namespace :que do
  desc 'Restarts que worker process'
  task :restart do
    on roles(:worker) do
      within release_path do
        invoke :'que:stop'
        info '[deploy:que] Starting que worker...'
        execute('start-stop-daemon',
                '--start',
                '--pidfile', "#{shared_path}/que_worker.pid",
                '--make-pidfile',
                "--chdir #{release_path}",
                '--background',
                '--exec', '/usr/bin/env',
                '--',
                'bundle', 'exec', 'que',
                '--worker-count', fetch(:que_worker_count),
                "#{release_path}/config/que.rb",
                '>>', "#{shared_path}/que_worker.log", '2>&1')
      end
    end
  end

  desc 'Stops current que worker process'
  task :stop do
    on roles(:worker) do
      within release_path do
        if test("[ -f #{shared_path}/que_worker.pid ]")
          info '[deploy:que] Killing que worker daemon'
          execute('start-stop-daemon',
                  '--stop',
                  '--oknodo',
                  '--pidfile', "#{shared_path}/que_worker.pid")
          execute(:rm, '-f', "#{shared_path}/que_worker.pid")
        end
      end
    end
  end

  after 'passenger:restart', 'que:restart'
end
