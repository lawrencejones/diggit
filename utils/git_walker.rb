#!/usr/bin/env ruby
require 'json'
require 'fileutils'
require 'commander/import'

require_relative './git_walker/walker'
require_relative './git_walker/metrics/file_size'
require_relative './git_walker/metrics/lines_of_code'
require_relative './git_walker/metrics/no_of_authors'

program :name, 'Git Walker'
program :version, '1.0.0'
program :description, 'Walk repo to output file tree'
program :help, %(
Example output...

    {
      "path": "/dir",
      "score": 123,
      "items": {
        "file": {
          "path": "/dir/file",
          "score": 123
        }
      }
    }
)

def get_metric_lambda(metric_label)
  GitWalker::Metrics.method(metric_label)

rescue NameError
  STDERR.puts("Metric #{metric_label} not supported!")
  exit(255)
end

command :walk do |c|
  c.syntax = 'walk <repo> <metric>'
  c.description = 'Scan repo to output metric score on each checked file'
  c.action do |(repo_path, metric_label)|
    walker = GitWalker::Walker.
      new(repo_path, metric_lambda: get_metric_lambda(metric_label))

    puts(JSON.pretty_generate(walker.frame))
  end
end
