PROJECT_ROOT = File.realpath(File.join(File.dirname(__FILE__), '..'))

class Diggit
  def initialize(path = PROJECT_ROOT)
    @path = path
  end

  attr_reader :path

  def info
    {
      node_version: node_version,
      ruby_version: ruby_version,
    }
  end

  def join(*args)
    File.join(@path, *args)
  end

  def node_version
    @node_version ||= File.read(File.join(@path, '.node-version')).chomp
  end

  def ruby_version
    @ruby_version ||= File.read(File.join(@path, '.ruby-version')).match(/\d+\.\d+\.\d+|/).to_s
  end
end
