#!/usr/bin/env ruby
require 'json'
require 'fileutils'

def usage
  prog = File.basename(__FILE__)
  puts %(
    Desc:  Walk given directory to output file tree
    Usage: #{prog} <metric> <path>
    Examples...

        #{prog} file-size /Users/home
        #{prog} lines-of-code /Projects/linux

    NB: More complex use cases (such as filtering files) should require
        the PathWalker and instrument from there.
  )
end

def main
  usage || exit(-1) unless ARGV.count == 2
  metric_label, root = ARGV

  metric = {
    'file-size' => ->(target) { File.size(target) },
    'lines-of-code' => ->(target) do
      %x{wc -l "#{target}"}.split.first.to_i
    end
  }.fetch(metric_label)


  puts(JSON.pretty_generate(PathWalker.new(root, metric_lambda: metric).frame))
end

# Walks a given directory to produce a recursive structure of each directory and file
# found from the root, computing a score for each file/directory using the supplied block.
#
# Example of...
#
#     PathWalker.new(ENV['HOME'], metric_lambda: ->(target) { File.size(target) })
#
# ...would walk the users home directory computing the recursive file size of each
# file/directory that is reachable from home.
class PathWalker
  def initialize(root, metric_lambda: nil)
    @root = File.realpath(root)
    @metric_lambda = metric_lambda
    @frame = compute_frame!
  end

  attr_reader :frame, :root

  private

  def compute_frame!(path = root)
    unless File.directory?(path)
      return { path: path, metric: @metric_lambda[path] }
    end

    ls(path).each_with_object({
      path: path,
      metric: 0,
      entries: {},
    }) do |target, frame|
      child_frame = compute_frame!(target)

      # Skip this entry if we've scored as a zero
      next if child_frame[:metric] == 0

      frame[:entries][File.basename(target)] = child_frame
      frame[:metric] += child_frame[:metric]
    end
  end

  def ls(path)
    return [] unless File.directory?(path)

    Dir.entries(path).
      reject { |entry| entry[0] == '.' }.
      map { |entry| File.join(path, entry) }
  end
end

# Run as a script if running as an executable
main if __FILE__ == $0

RSpec.describe(PathWalker) do
  subject(:snapshot) do
    described_class.new(tmp, metric_lambda: metric)
  end

  let(:tmp) { Dir.mktmpdir }
  let(:metric) { ->(target) { File.size(target) } }

  before do
    raise 'Bad setup command' unless system %(
    mkdir #{tmp}/root
    dd if=/dev/zero of="#{tmp}/root/1K"  bs=1k  count=1
    dd if=/dev/zero of="#{tmp}/root/2M"  bs=1m  count=2
    )
  end

  after { FileUtils.rm_rf(tmp) }

  describe '.frame' do
    subject(:frame) { snapshot.frame }

    it 'computes metric for files', :aggregate_failures do
      expect(frame[:entries]['root'][:entries]['1K'][:metric]).to eq(1 << 10)  # 1KB
      expect(frame[:entries]['root'][:entries]['2M'][:metric]).to eq(2 * (1 << 20))  # 2MB
    end

    it 'aggregates metric for directories' do
      expect(frame[:metric]).to be_within(1 << 9).of((1 << 10) + (2 * (1 << 20)))
    end
  end
end if defined?(RSpec)
