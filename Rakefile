require 'bundler/gem_tasks'

desc "Open an irb console with gem environment loaded"

task :console do
  require 'irb'
  require 'irb/completion'
  require 'mina_provision'
  ARGV.clear
  IRB.start
end
