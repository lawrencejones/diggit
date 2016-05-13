require_relative '../lib/diggit/system'
Diggit::System.init

Dir.glob('lib/diggit/jobs/*.rb').each { |r| require_relative(r) }
