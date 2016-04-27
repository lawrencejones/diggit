set :application, 'diggit'
set :repo_url, 'git@github.com:lawrencejones/diggit'
set :scm, :git

set :default, 'RACK_ENV' => 'production'
set :deploy_to, '/var/www/diggit'
set :deploy_user, 'deploy'

set :format, :pretty
set :log_level, :info

set :linked_dirs, %w(log node_modules web/jspm_packages)
set :linked_files, %w(env)
set :keep_releases, 5

set :rbenv_type, :system
set :rbenv_ruby, File.read('.ruby-version').strip

set :npm_flags, '--silent --no-progress'

set :rollbar_token, 'ec9c852990434032a468c375890576ce'
set :rollbar_env, proc { fetch :stage }
set :rollbar_role, proc { :app }
