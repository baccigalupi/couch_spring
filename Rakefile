require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "couch_db"
    gem.summary = %Q{A slim CouchSpring API wrapper}
    gem.description = %Q{This is a close to the API wrapper for CouchSpring that aims to be the foundation for Aqua, CouchRest and other CouchSpring Document abstractions.}
    gem.email = "baccigalupi@gmail.com"
    gem.homepage = "http://github.com/baccigalupi/couchdb"
    gem.authors = ["Kane Baccigalupi"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "yard", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = '--color'
end

# 
# Spec::Rake::SpecTask.new(:rcov) do |spec|
#   spec.libs << 'lib' << 'spec'
#   spec.pattern = 'spec/**/*_spec.rb'
#   spec.rcov = true
# end

task :spec => :check_dependencies

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
