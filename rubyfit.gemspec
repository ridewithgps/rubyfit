# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rubyfit/version"

Gem::Specification.new do |s|
  s.name        = "rubyfit"
  s.version     = Rubyfit::VERSION
  s.authors     = ["Cullen King"]
  s.email       = ["cullen@ridewithgps.com"]
  s.homepage    = "http://cullenking.com"
  s.summary     = %q{A stream based parser for FIT files.}
  s.description = %q{FIT files are binary, and as a result, are a pain to parse.  This is a wrapper around the FIT SDK, which makes creating a stream based parser simple.}

  s.rubyforge_project = "rubyfit"

  #s.files         = `git ls-files`.split("\n")
  s.files = Dir.glob('lib/**/*.rb') + Dir.glob('ext/**/*.{c,h,rb}')
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib", "ext"]

  s.extensions << 'ext/rubyfit/extconf.rb'

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
