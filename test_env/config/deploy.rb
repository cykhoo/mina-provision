require 'mina_provision/tasks'

set :domain,        '172.16.86.122'
set :user,          'deployer'
set :forward_agent, true
set :port,          '22'
set :deploy_to,     ''

set :timezone,      'Asia/Singapore'
set :ruby_version,  '2.2.1'
set :app_name,      'guides'
set :cert_name,     'cantab-ip.com'

task :environment do
  queue %{ echo "-----> Loading ~/.bash_profile"
           #{echo_cmd %[source ~/.bash_profile]}   }
  invoke :'rbenv:load'
end

desc "Provisions server"
# Requirements: sudo installed, user with sudo privileges, public key installed
task :provision do
  invoke :swap
  invoke :profile
  invoke :sshd
  invoke :locales
  invoke :packages
  invoke :rbenv
  invoke :ruby
  invoke :hostname
end
