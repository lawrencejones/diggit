#!/usr/bin/env ruby
# encoding: utf-8
require 'json'
require 'fileutils'
require 'commander/import'

require_relative './git_walker/walker'
require_relative './git_walker/metrics/file_size'
require_relative './git_walker/metrics/lines_of_code'
require_relative './git_walker/metrics/no_of_authors'
require_relative './git_walker/metrics/complexity'

program :name, 'Git Walker'
program :version, '1.0.0'
program :description, 'Walk repo to output file tree'

def available_metrics
  GitWalker::Metrics.methods - Module.methods
end

def get_metric_lambda(metric_label)
  GitWalker::Metrics.method(metric_label)

rescue NameError
  STDERR.puts %(
  Metric '#{metric_label}' is not supported!
  Please use one of [#{available_metrics.join(', ')}]
  )
  exit(255)
end

default_command :walk
command :walk do |c|
  c.syntax = 'walk <repo>'
  c.description = 'Scan repo to output metric score on each checked file'
  c.option '--metric METRIC', String, "One of #{available_metrics.join(', ')}"
  c.option '--pattern PATTERN', String, 'Shell file glob to filter files'

  c.action do |(repo_path), options|
    walker = GitWalker::Walker.
      new(repo_path,
          metric_lambda: get_metric_lambda(options.metric),
          file_glob: options.pattern)

    puts(JSON.pretty_generate(walker.frame))
  end
end
