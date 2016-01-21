#!/usr/bin/env ruby
require 'json'
require 'fileutils'
require_relative './git_walker/walker'

def usage
  prog = File.basename(__FILE__)
  puts %(
    Desc:  Walk given repo to output file tree
    Usage: #{prog} <repo> <metric>
    Examples...

        #{prog} /Projects/arm file-size
        #{prog} /Projects/linux lines-of-code

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
        the GitWalker::Walker and instrument from there.
  )
end

usage || exit(-1) unless ARGV.count == 2
root, metric_label = ARGV

metric = {
  'file-size' => ->(target) { File.size(target) },
  'lines-of-code' => lambda do |target|
    return 0 if File.directory?(target)

    `wc -l "#{target}"`.split.first.to_i
  end,
}.fetch(metric_label)

puts(JSON.pretty_generate(GitWalker::Walker.new(root, metric_lambda: metric).frame))
