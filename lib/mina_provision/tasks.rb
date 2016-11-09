require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'

desc "Setup swapfile for virtual memory"
task :swap do
  command %[sudo fallocate -l 1G /swapfile]
  command %[sudo chmod 600 /swapfile]
  command %[sudo mkswap /swapfile]
  command %[sudo swapon /swapfile]
  command %[sudo sed -i '$a\/swapfile       none            swap    sw                0       0' /etc/fstab]

  command %[sudo sysctl vm.swappiness=10]
  command %[sudo sysctl vm.vfs_cache_pressure=50]

  command %[sudo sed -i '$a\/vm.swappiness=10' /etc/sysctl.conf]
  command %[sudo sed -i '$a\/sysctl vm.vfs_cache_pressure=50' /etc/sysctl.conf]

  command %[sudo swapon -s]
  command %[free -h]
end

desc "Setup Bash profile and miscellaneous settings"
task :profile do
  invoke 'profile:config_bash'
  invoke 'profile:config_editor'
  invoke 'profile:config_tmux'
  invoke 'profile:config_timezone'
  invoke 'profile:config_colours'
end

namespace :profile do

  desc "Setup Bash profile to source .bashrc if present"
  task :config_bash do
    command %[echo '# Load settings in .bashrc if present' >> ~/.bash_profile]
    command %[echo "if [ -f ~/.bashrc ]; then" >> ~/.bash_profile]
    command %[echo "  source ~/.bashrc" >> ~/.bash_profile]
    command %[echo "fi" >> ~/.bash_profile]
  end

  desc "Setup Vim as default editor"
  task :config_editor do
    command %[sudo apt-get -y install vim]
    command %[sudo update-alternatives --set editor /usr/bin/vim.basic]
  end

  desc "Install tmux as terminal multiplexer"
  task :config_tmux do
    command %[sudo apt-get -y install tmux]
    command %[echo 'set -g default-terminal "screen-256color"' > .tmux.conf]
  end

  desc "Setup correct colours"
  task :config_colours do
    # Allows colour prompt with broader range of terminal types
    command %[sed -i 's/xterm-color) color_prompt=yes;;/*color) color_prompt=yes;;/i' ~/.bashrc]
  end

  desc "Setup correct timezone"
  task :config_timezone do
    command %[echo "#{fetch(:timezone)}" | sudo tee /etc/timezone  ]
    command %[sudo cp "/usr/share/zoneinfo/#{fetch(:timezone)}" /etc/localtime]
  end
end

desc "Configure SSH daemon"
task :sshd do
  invoke 'sshd:config'
end

namespace :sshd do

  desc "Configure SSH daemon with initial settings"
  task :config do
    command %[sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/i' /etc/ssh/sshd_config]
    command %[sudo sed -i 's/X11Forwarding yes/X11Forwarding no/i' /etc/ssh/sshd_config]
    command %[sudo sed -i 's/UsePAM yes/UsePAM no/i' /etc/ssh/sshd_config]

    command %[sudo sed -i '$a\\\n' /etc/ssh/sshd_config]
    command %[sudo sed -i '$a\UseDNS no' /etc/ssh/sshd_config]
    command %[sudo sed -i '$a\AllowUsers #{fetch(:user)}' /etc/ssh/sshd_config]

    command %[sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/i' /etc/ssh/sshd_config]
  end
end

desc "Configure locales"
task :locales do
  invoke 'locales:config'
end

namespace :locales do

  desc "Configure locales with en_GB.UTF-8"
  task :config do
    command %[sudo sed -i 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/i' /etc/locale.gen]
    command %[sudo sed -i 's/^en_SG.UTF-8 UTF-8/# en_SG.UTF-8 UTF-8/i' /etc/locale.gen]
    command %[sudo locale-gen --purge en_GB.UTF-8]
    command %[sudo sed -i 's/en_SG/en_GB/i' /etc/default/locale]

    command %[echo -n "\n" >> ~/.bash_profile]
    command %[echo '# Set the language of the system' >> .bash_profile]
    command %[echo 'LANG="en_GB.UTF-8"' >> .bash_profile]
    command %[echo 'LANGUAGE="en_GB.UTF-8"' >> .bash_profile]
  end
end

desc "Update repos and install dependencies"
task :packages do
  invoke 'packages:update'
  invoke 'packages:install'
end

namespace 'packages' do

  desc "Update repositories using apt-get"
  task :update do
    command %[sudo apt-get -y update]
  end

  desc "Install dependencies for programs to be installed"
  task :install do
    command %[sudo apt-get -y install curl git-core build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libcurl4-openssl-dev libxml2-dev libxslt1-dev python-software-properties autoconf bison libreadline6-dev zlib1g-dev libncurses5-dev]
  end
end

desc "Install rbenv, rbenv plugins and test"
task :rbenv do
  invoke 'rbenv:install_rbenv'
  invoke 'rbenv:install_rbenv_binstubs'
  invoke 'rbenv:install_rbenv_gem_rehash'
  invoke 'rbenv:install_rbenv_update'
  invoke 'rbenv:install_rbenv_vars'
  invoke 'rbenv:test_rbenv'
end

namespace 'rbenv' do

  desc "Install rbenv"
  task :install_rbenv do
    command %[git clone https://github.com/sstephenson/rbenv.git ~/.rbenv]
    command %[git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build]

    command %[echo -n "\n" >> ~/.bash_profile]
    command %[echo '# Add ~/.rbenv/bin to your $PATH for access to the rbenv command-line utility' >> ~/.bash_profile]
    command %[echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile]

    command %[echo  -n "\n" >> ~/.bash_profile]
    command %[echo '# Add rbenv init to your shell to enable shims and autocompletion' >> ~/.bash_profile]
    command %[echo 'eval "$(rbenv init -)"' >> ~/.bash_profile]
  end

  desc "Install rbenv-binstubs plugin"
  task :install_rbenv_binstubs do
    command %[git clone https://github.com/ianheggie/rbenv-binstubs.git ~/.rbenv/plugins/rbenv-binstubs]
  end

  desc "Install rbenv-gem-rehash plugin"
  task :install_rbenv_gem_rehash do
    command %[git clone https://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash]
  end

  desc "Install rbenv-update plugin"
  task :install_rbenv_update do
    command %[git clone https://github.com/rkh/rbenv-update.git ~/.rbenv/plugins/rbenv-update]
  end

  desc "Install rbenv-vars plugin"
  task :install_rbenv_vars do
    command %[git clone https://github.com/sstephenson/rbenv-vars.git ~/.rbenv/plugins/rbenv-vars]
  end

  desc "Test rbenv"
  task :test_rbenv do
    command %[source .bash_profile]
    command %[type rbenv]
  end
end

desc "Install Ruby #{fetch(:ruby_version)}, RubyGems, Bundler and setup"
task :ruby do
  invoke 'ruby:install_dependencies'
  invoke 'ruby:install_ruby'
  invoke 'ruby:set_default_ruby'
  invoke 'ruby:setup_rubygems'
  invoke 'ruby:setup_bundler'
  invoke 'ruby:setup_irb'
  invoke 'ruby:install_bundler'
end

namespace 'ruby' do

  desc "Install dependencies for Ruby"
  task :install_dependencies => :environment do
    # install other libraries needed for installing Ruby, from rbenv docs
    command %[sudo apt-get -y install libffi-dev libgdbm-dev libgdbm3]
  end

  desc "Install Ruby"
  task :install_ruby => :environment do
    command %[CONFIGURE_OPTS="--disable-install-doc" rbenv install "#{fetch(:ruby_version)}" --verbose]
  end

  desc "Set default Ruby version"
  task :set_default_ruby => :environment do
    command %[echo "#{fetch(:ruby_version)}" > .ruby-version]
  end

  desc "Setup defaults for Rubygems"
  task :setup_rubygems => :environment do
    command %[echo 'install: --no-rdoc --no-ri' >> .gemrc]
    command %[echo 'update:  --no-rdoc --no-ri' >> .gemrc]
  end

  desc "Setup defaults for Bundler"
  task :setup_bundler => :environment do
    command %[mkdir .bundle]
    command %[echo '---'                             >> .bundle/config]
    command %[NUMBER_CORES=$(grep -c processor /proc/cpuinfo)]
    command %[if [ $NUMBER_CORES -gt 1 ]; then ]
    command %[    NUMBER_CORES=$((NUMBER_CORES - 1))]
    command %[fi]
    command %[echo "BUNDLE_PATH_JOBS: '$NUMBER_CORES'"           >> .bundle/config]
    command %[echo "BUNDLE_PATH: 'vendor'"           >> .bundle/config]
    command %[echo "BUNDLE_DISABLE_SHARED_GEMS: '1'" >> .bundle/config]
  end

  desc "Setup defaults for IRB"
  task :setup_irb => :environment do
    command %[echo "require 'irb/ext/save-history'"                            >> .irbrc]
    command %[echo ""                                                          >> .irbrc]
    command %[echo "IRB.conf[:SAVE_HISTORY] = 100"                             >> .irbrc]
    command %[echo "IRB.conf[:HISTORY_FILE] = '~/.irb_history' >> .irbrc"]
  end

  desc "Install bundler gem"
  task :install_bundler => :environment do
    command %[gem install bundler]
  end
end

desc "Change host name"
task :hostname => :environment do
  set :hostname, fetch(:domain).split('.')[0]
  command %[echo '#{fetch(:hostname)}' | sudo tee /etc/hostname]
end

desc "Provision Rails server"
task :provision_rails => :environment do
  invoke :'rails:install_server'
end

namespace 'rails' do

  desc "Install software for Rails server: Javascript runtime, PostgreSQL database, Nginx web server"
  task :install_server => :environment do
    invoke :'misc:install_javascript'
    invoke :'misc:install_postgres'
    invoke :'misc:config_postgres'
    invoke :'misc:install_nginx'
    invoke :'misc:config_nginx'
    invoke :'misc:install_smem'
  end
end

namespace 'misc' do

  desc "Install Javascript runtime (NodeJs)"
  task :install_javascript => :environment do
    command %[sudo apt-get -y install nodejs]
  end

  desc "Install PostgreSQL"
  task :install_postgres => :environment do
    command %[sudo apt-get -y install postgresql postgresql-contrib]
    command %[sudo apt-get -y install libpq-dev] # dependency for pg gem
    command %[echo 'Remember to ssh in to set up Postgres user and create database...']
  end

  desc "Configure PostgreSQL"
  task :config_postgres => :environment do
    command %[sudo -u postgres psql -c \"CREATE USER #{fetch(:app_name)} WITH PASSWORD \'#{fetch(:app_name)}\';\"]
    command %[sudo -u postgres psql -c \"ALTER ROLE #{fetch(:app_name)} WITH CREATEDB;\"]
    command %[sudo -u postgres psql -c \"CREATE DATABASE #{fetch(:app_name)}_production OWNER #{fetch(:app_name)};\"]
  end

  desc "Install memcached"
  task :install_memcached => :environment do
    command %[sudo apt-get -y install memcached]
  end

  desc "Install redis"
  task :install_redis => :environment do
    command %[sudo apt-get -y install redis-server]
  end

  desc "Install nginx"
  task :install_nginx => :environment do
    command %[sudo apt-get -y install nginx]
  end

  desc "Configure Nginx"
  task :config_nginx => :environment do
    set :template_dir,            File.expand_path('../templates', __FILE__)
    set :nginx_template_location, fetch(:template_dir) + '/nginx_conf.erb'
    set :app_nginx_config,        erb(fetch(:nginx_template_location))
    command %[echo -n '#{fetch(:app_nginx_config)}' | sudo tee /etc/nginx/sites-available/#{fetch(:app_name)}]
    command %[sudo ln -s /etc/nginx/sites-available/#{fetch(:app_name)} /etc/nginx/sites-enabled/#{fetch(:app_name)}]
    command %[sudo rm /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default]
    command %[sudo service nginx restart]
  end

  desc "Install smem"
  task :install_smem => :environment do
    command %[sudo apt-get -y install smem]
  end
end
