$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$stdout.sync = true
require './diggit'
run Diggit::App
