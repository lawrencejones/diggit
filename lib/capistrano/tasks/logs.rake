namespace :logs do
  desc 'Tail role logs'
  task :tail, :role do |t, args|
    on roles(args.fetch(:role)) do
      trap('INT') { exit 0 }
      SSHKit.config.output_verbosity = Logger::DEBUG
      SSHKit.config.use_format :simpletext
      execute "tail -f #{shared_path}/log/diggit.log"
    end
  end
end
