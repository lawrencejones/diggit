#!/usr/bin/env ruby
require 'json'
require 'fileutils'
require 'commander/import'
require_relative './git_walker/walker'

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

NB: More complex use cases (such as filtering files) should require
    the GitWalker::Walker and instrument from there.)

builtin_metric_lambdas = {
  'file-size' => ->(target) { File.size(target) },
  'lines-of-code' => lambda do |target|
    return 0 if File.directory?(target)

    `wc -l "#{target}"`.split.first.to_i
  end,
}

command :walk do |c|
  c.syntax = 'walk <repo> <metric>'
  c.description = 'Scan repo to output metric score on each checked file'
  c.action do |(repo_path, metric_label)|
    walker = GitWalker::Walker.
      new(repo_path, metric_lambda: builtin_metric_lambdas.fetch(metric_label))

    puts(JSON.pretty_generate(walker.frame))
  end
end
