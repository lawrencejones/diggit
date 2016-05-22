$LOAD_PATH << 'lib'

require_relative 'lib/tasks/db'
require_relative 'lib/tasks/integ'
require_relative 'lib/tasks/one_off'
require_relative 'lib/tasks/frequent_pattern'
require_relative 'lib/tasks/analysis'

task :init do
  require 'diggit/system'
  Diggit::System.init
end

# Enforce system being booted before each task
current_tasks = Rake.application.top_level_tasks
current_tasks.unshift(:init)
Rake.application.instance_variable_set(:@top_level_tasks, current_tasks)
