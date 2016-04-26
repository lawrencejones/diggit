require_relative 'lib/tasks/db'
require_relative 'lib/tasks/integ'

namespace :deploy do
  desc 'Deploy diggit'
  task :production, [:branch] do |_t, args|
    app = 'diggit'
    remote = "https://git.heroku.com/#{app}.git"
    branch = args.fetch(:branch, 'master')

    system "heroku maintenance:on --app #{app}"
    system "git push --force #{remote} #{branch}:master"
    system 'heroku run rake db:migrate db:que_setup'
    system "heroku maintenance:off --app #{app}"

    system 'echo "Pinging diggit... " && curl https://diggit.herokuapp.com/api/ping'
  end
end

namespace :heroku do
  desc 'Configures node & ruby buildpacks for heroku'
  task :configure_buildpacks do
    puts('Resetting heroku buildpacks...')
    system 'heroku buildpacks:clear'
    system 'heroku buildpacks:add heroku/nodejs'
    system 'heroku buildpacks:add heroku/ruby'
    puts('Done!')
  end
end
