require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require File.join(File.expand_path(File.dirname(__FILE__)),'lib','simple_stats')

begin
  require 'spec/rake/spectask'
rescue LoadError
  puts 'To use rspec for testing you must install rspec gem:'
  puts '$ sudo gem install rspec'
  exit
end

spec = Gem::Specification.new do |s|
  s.name = "simple-stats"
  s.version = SimpleStats::VERSION
  s.date = "2009-11-22"
  s.summary = "Lean and easy stats library for your application model"
  s.email = "taylor.luk@idealian.net"
  s.homepage = "http://simple-stats.com"
  s.description = ""
  s.has_rdoc = true
  s.authors = ["Taylor Luk"]
  s.files = %w(README.md Rakefile history.txt) + 
    Dir["{lib,rails,spec}/**/*"] - 
    Dir["spec/tmp"]
  s.extra_rdoc_files = %w( README.md )
  s.require_path = "lib"
  s.add_dependency("couchrest", ">= 0.3")
end

desc "Run the specs under spec"
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "spec/spec.opts"]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

desc "Print specdocs"
Spec::Rake::SpecTask.new(:doc) do |t|
	t.spec_opts = ["--format", "specdoc"]
	t.spec_files = FileList['spec/*_spec.rb']
end

desc "Default task is to run specs"
task :default => :spec

# Make a console, useful when working on tests
desc "Generate a test console"
task :console do
   verbose( false ) { sh "irb -I lib/ -r 'simple_stats'" }
end
