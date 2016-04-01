require 'sinatra/activerecord/rake'
require_relative 'lib/diggit/system'

namespace :db do
  task :que_setup do
    Diggit::System.init
    Que.migrate!
  end

  task :load_config do
    Diggit::System.init
  end
end
