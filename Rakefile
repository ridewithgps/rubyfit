require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rake/extensiontask'

desc "Specs"
RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = "spec/**/*_spec.rb"
  t.verbose = true
end

gemspec = Gem::Specification.load('rubyfit.gemspec')
Rake::ExtensionTask.new do |ext|
  ext.name = 'rubyfit'
  ext.source_pattern = "*.{c,h}"
  ext.ext_dir = 'ext/rubyfit'
  ext.lib_dir = 'lib/rubyfit'
  ext.gem_spec = gemspec
end

task :clean do
  FileUtils.rm_rf("tmp/")
end

task :default => [:compile, :test]
