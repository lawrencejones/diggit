require 'sinatra/activerecord/rake'

namespace :db do
  task :que_setup do
    require './diggit'
    Que.migrate!
  end

  task :load_config do
    require './diggit'
  end
end
