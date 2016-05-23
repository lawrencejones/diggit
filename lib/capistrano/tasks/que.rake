namespace :que do
  desc 'Restarts que worker process'
  task :restart do
    on roles(:worker) do
      within release_path do
        invoke :'que:stop'
        (1..fetch(:que_worker_count) / 2).each do |i|
          info "[deploy:que] Starting que##{i}..."
          execute('start-stop-daemon',
                  '--start',
                  '--pidfile', "#{shared_path}/que_worker_#{i}.pid",
                  '--make-pidfile',
                  "--chdir #{release_path}",
                  '--background',
                  '--exec', '/usr/bin/env',
                  '--',
                  'bundle', 'exec', 'que',
                  '--worker-count', '2', # start each process with pool of 2
                  "#{release_path}/config/que.rb",
                  '>>', "#{shared_path}/que_worker.log", '2>&1')
        end
      end
    end
  end

  desc 'Stops current que worker process'
  task :stop do
    on roles(:worker) do
      within release_path do
        (1..fetch(:que_worker_count) / 2).each do |i|
          next if test("[ -f #{shared_path}/que_worker_#{i}.pid ]")

          info "[deploy:que] Killing que##{i} daemon"
          execute('start-stop-daemon',
                  '--stop',
                  '--oknodo',
                  '--pidfile', "#{shared_path}/que_worker_#{i}.pid")
          execute(:rm, '-f', "#{shared_path}/que_worker_#{i}.pid")
        end
      end
    end
  end

  after 'deploy:publishing', 'que:restart'
end
