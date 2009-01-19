require 'rubygems'
gem 'echoe', '~> 3.0.1'
require 'echoe'
require './lib/cloudfiles.rb'
 
echoe = Echoe.new('cloudfiles') do |p|
  p.author = ["H. Wade Minter", "Rackspace Hosting"]
  p.email = 'wade.minter@rackspace.com'
  p.version = CloudFiles::VERSION
  p.summary = "A Ruby API into Mosso Cloud Files"
  p.description = 'A Ruby version of the Mosso Cloud Files API.'
  p.url = "http://www.mosso.com/cloudfiles.jsp"
end

desc 'Generate the .gemspec file in the root directory'
task :gemspec do
  File.open("#{echoe.name}.gemspec", "w") {|f| f << echoe.spec.to_ruby }
end
task :package => :gemspec

