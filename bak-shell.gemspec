# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),"lib","bak-shell","version.rb"])
Gem::Specification.new do |s|
  s.name     = "bak"
  s.version  = BakShell::VERSION
  s.author   = "Robert Audi"
  s.email    = "robert@audii.me"
  s.homepage = "https://github.com/RobertAudi/bak-shell"
  s.summary  = "Backup utility for the shell"
  s.license  = "MIT"
  s.files    = `git ls-files -z`.split("\x0")

  s.bindir        = "bin"
  s.require_paths << "lib"
  s.executables   << "bak"

  s.add_development_dependency "rake"
  s.add_development_dependency "bundler", "~> 1.6"

  s.add_runtime_dependency "gli", "2.11.0"
end
