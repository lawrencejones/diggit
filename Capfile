# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

# Capistrano gems
require 'capistrano/bundler'
require 'capistrano/passenger'
require 'capistrano/rbenv'
require 'capistrano/rails/migrations'

# Load custom tasks from `lib/capistrano/tasks`
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
