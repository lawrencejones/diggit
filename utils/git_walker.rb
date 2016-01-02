#!/usr/bin/env ruby
require 'json'
require 'fileutils'

def usage
  prog = File.basename(__FILE__)
  puts %(
    Desc:  Walk given repo to output file tree
    Usage: #{prog} <metric> <repo>
    Examples...

        #{prog} file-size /Projects/arm
        #{prog} lines-of-code /Projects/linux

    NB: More complex use cases (such as filtering files) should require
        the GitWalker and instrument from there.
  )
end

def main
  usage || exit(-1) unless ARGV.count == 2
  metric_label, root = ARGV

  metric = {
    'file-size' => ->(target) { File.size(target) },
    'lines-of-code' => ->(target) do
      return 0 if File.directory?(target)

      %x{wc -l "#{target}"}.split.first.to_i
    end
  }.fetch(metric_label)


  puts(JSON.pretty_generate(GitWalker.new(root, metric_lambda: metric).frame))
end

# Walks a given git repo to produce a recursive structure of each directory and file
# found from the root, computing a score for each file/directory using the supplied block.
#
# Example of...
#
#     GitWalker.new(repo_path, metric_lambda: ->(target) { File.size(target) })
#
# ...would walk the repo at `repo_path`, computing the recursive file size of each
# file/directory that is tracked by the repo.
class GitWalker
  def initialize(root, metric_lambda: nil)
    @root = File.realpath(root)
    verify_root!

    @metric_lambda = metric_lambda
    @frame = compute_frame
  end

  attr_reader :frame, :root
  private

  def verify_root!
    unless git_exec('rev-parse --is-inside-work-tree') == 'true'
      raise "Is not valid git repository! #{@root}"
    end
  end

  def git_exec(cmd)
    %x{GIT_DIR="#{@root}/.git" git #{cmd}}.chomp
  end

  def all_tracked_files
    git_exec('ls-files').split
  end

  def compute_frame
    all_tracked_files.each_with_object(new_frame) do |file, frame|
      metric_value = compute_metric(file)
      frame[:metric] += metric_value

      directories = file.split(File::SEPARATOR)
      basename = directories.pop

      sub_frame = directories.reduce(frame) do |frm, dir|
        frm[:entries][dir] ||= new_frame(File.join(frm[:path], dir))
        frm[:entries][dir].tap { |f| f[:metric] += metric_value }
      end

      sub_frame[:entries][basename] = { path: file, metric: metric_value }
    end
  end

  def new_frame(path = @root)
    { path: path, entries: {}, metric: 0 }
  end

  def compute_metric(target)
    @metric_lambda[File.join(@root, target)]
  end
end

# Run as a script if running as an executable
main if __FILE__ == $0

RSpec.describe(GitWalker) do
  subject(:walker) do
    described_class.new(tmp, metric_lambda: metric)
  end

  let(:tmp) { Dir.mktmpdir }
  let(:metric) { ->(target) { File.size(target) } }

  before do
    raise 'Bad setup command' unless system %(
    mkdir #{tmp}/root
    cd #{tmp}
    git init
    dd if=/dev/zero of="#{tmp}/root/1K"  bs=1k  count=1
    dd if=/dev/zero of="#{tmp}/root/2M"  bs=1m  count=2
    git add -A
    git commit -am "Initial commit"
    )
  end

  after { FileUtils.rm_rf(tmp) }

  describe '.frame' do
    subject(:frame) { walker.frame }

    it 'computes metric for files', :aggregate_failures do
      expect(frame[:entries]['root'][:entries]['1K'][:metric]).to eq(1 << 10)  # 1KB
      expect(frame[:entries]['root'][:entries]['2M'][:metric]).to eq(2 * (1 << 20))  # 2MB
    end

    it 'aggregates metric for directories' do
      expect(frame[:metric]).to be_within(1 << 9).of((1 << 10) + (2 * (1 << 20)))
    end
  end
end if defined?(RSpec)
