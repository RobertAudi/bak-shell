require 'rake/clean'
require 'rubygems'
require 'rubygems/package_task'

spec = eval(File.read('bak-shell.gemspec'))

Gem::PackageTask.new(spec) do |pkg|
end
task :default => :package
