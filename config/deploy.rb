set :application, 'diggit'
set :repo_url, 'git@github.com:lawrencejones/diggit'
set :scm, :git

set :deploy_to, '/var/www/diggit'
set :deploy_user, 'deploy'

set :format, :pretty
set :log_level, :debug

set :linked_dirs, %w(log)
set :keep_releases, 5

set :rbenv_type, :system
set :rbenv_ruby, File.read('.ruby-version').strip
