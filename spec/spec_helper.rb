require 'rspec'
require_relative '../diggit.rb'

$LOAD_PATH << '../lib'

def load_fixture(file)
  File.read(File.join(File.dirname(__FILE__), 'fixtures', file))
end
