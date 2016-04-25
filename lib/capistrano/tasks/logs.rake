namespace :logs do
  desc 'Tail server logs'
  task :tail do
    on roles(:app) do
      trap('INT') { exit 0 }
      execute "tail -f #{shared_path}/log/{diggit,error}.log"
    end
  end
end
