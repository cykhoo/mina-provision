require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'

desc "Setup swapfile for virtual memory"
task :swap do
  queue! %[sudo fallocate -l 1G /swapfile]
  queue! %[sudo chmod 600 /swapfile]
  queue! %[sudo mkswap /swapfile]
  queue! %[sudo swapon /swapfile]
  queue! %[sudo sed -i '$a\/swapfile       none            swap    sw                0       0' /etc/fstab]

  queue! %[sudo sysctl vm.swappiness=10]
  queue! %[sudo sysctl vm.vfs_cache_pressure=50]

  queue! %[sudo sed -i '$a\/vm.swappiness=10' /etc/sysctl.conf]
  queue! %[sudo sed -i '$a\/sysctl vm.vfs_cache_pressure=50' /etc/sysctl.conf]

  queue! %[sudo swapon -s]
  queue! %[free -h]
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
    queue! %[echo '# Load settings in .bashrc if present' >> ~/.bash_profile]
    queue! %[echo "if [ -f ~/.bashrc ]; then" >> ~/.bash_profile]
    queue! %[echo "  source ~/.bashrc" >> ~/.bash_profile]
    queue! %[echo "fi" >> ~/.bash_profile]
  end

  desc "Setup Vim as default editor"
  task :config_editor do
    queue! %[sudo apt-get -y install vim]
    queue! %[sudo update-alternatives --set editor /usr/bin/vim.basic]
  end

  desc "Install tmux as terminal multiplexer"
  task :config_tmux do
    queue! %[sudo apt-get -y install tmux]
    queue! %[echo 'set -g default-terminal "screen-256color"' > .tmux.conf]
  end

  desc "Setup correct colours"
  task :config_colours do
    # Allows colour prompt with broader range of terminal types
    queue! %[sed -i 's/xterm-color) color_prompt=yes;;/*color) color_prompt=yes;;/i' ~/.bashrc]
  end

  desc "Setup correct timezone"
  task :config_timezone do
    queue! %[echo "#{timezone}" | sudo tee /etc/timezone  ]
    queue! %[sudo cp "/usr/share/zoneinfo/#{timezone}" /etc/localtime]
  end
end

desc "Configure SSH daemon"
task :sshd do
  invoke 'sshd:config'
end

namespace :sshd do

  desc "Configure SSH daemon with initial settings"
  task :config do
    queue! %[sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/i' /etc/ssh/sshd_config]
    queue! %[sudo sed -i 's/X11Forwarding yes/X11Forwarding no/i' /etc/ssh/sshd_config]
    queue! %[sudo sed -i 's/UsePAM yes/UsePAM no/i' /etc/ssh/sshd_config]

    queue! %[sudo sed -i '$a\\\n' /etc/ssh/sshd_config]
    queue! %[sudo sed -i '$a\UseDNS no' /etc/ssh/sshd_config]
    queue! %[sudo sed -i '$a\AllowUsers #{user}' /etc/ssh/sshd_config]

    queue! %[sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/i' /etc/ssh/sshd_config]
  end
end

desc "Configure locales"
task :locales do
  invoke 'locales:config'
end

namespace :locales do

  desc "Configure locales with en_GB.UTF-8"
  task :config do
    queue! %[sudo sed -i 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/i' /etc/locale.gen]
    queue! %[sudo sed -i 's/^en_SG.UTF-8 UTF-8/# en_SG.UTF-8 UTF-8/i' /etc/locale.gen]
    queue! %[sudo locale-gen --purge en_GB.UTF-8]
    queue! %[sudo sed -i 's/en_SG/en_GB/i' /etc/default/locale]

    queue! %[echo -n "\n" >> ~/.bash_profile]
    queue! %[echo '# Set the language of the system' >> .bash_profile]
    queue! %[echo 'LANG="en_GB.UTF-8"' >> .bash_profile]
    queue! %[echo 'LANGUAGE="en_GB.UTF-8"' >> .bash_profile]
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
    queue! %[sudo apt-get -y update]
  end

  desc "Install dependencies for programs to be installed"
  task :install do
    queue! %[sudo apt-get -y install curl git-core build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libcurl4-openssl-dev libxml2-dev libxslt1-dev python-software-properties autoconf bison libreadline6-dev zlib1g-dev libncurses5-dev]
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
    queue! %[git clone https://github.com/sstephenson/rbenv.git ~/.rbenv]
    queue! %[git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build]

    queue! %[echo -n "\n" >> ~/.bash_profile]
    queue! %[echo '# Add ~/.rbenv/bin to your $PATH for access to the rbenv command-line utility' >> ~/.bash_profile]
    queue! %[echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile]

    queue! %[echo  -n "\n" >> ~/.bash_profile]
    queue! %[echo '# Add rbenv init to your shell to enable shims and autocompletion' >> ~/.bash_profile]
    queue! %[echo 'eval "$(rbenv init -)"' >> ~/.bash_profile]
  end

  desc "Install rbenv-binstubs plugin"
  task :install_rbenv_binstubs do
    queue! %[git clone https://github.com/ianheggie/rbenv-binstubs.git ~/.rbenv/plugins/rbenv-binstubs]
  end

  desc "Install rbenv-gem-rehash plugin"
  task :install_rbenv_gem_rehash do
    queue! %[git clone https://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash]
  end

  desc "Install rbenv-update plugin"
  task :install_rbenv_update do
    queue! %[git clone https://github.com/rkh/rbenv-update.git ~/.rbenv/plugins/rbenv-update]
  end

  desc "Install rbenv-vars plugin"
  task :install_rbenv_vars do
    queue! %[git clone https://github.com/sstephenson/rbenv-vars.git ~/.rbenv/plugins/rbenv-vars]
  end

  desc "Test rbenv"
  task :test_rbenv do
    queue! %[source .bash_profile]
    queue! %[type rbenv]
  end
end

desc "Install Ruby #{ruby_version}, RubyGems, Bundler and setup"
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
    queue! %[sudo apt-get -y install libffi-dev libgdbm-dev libgdbm3]
  end

  desc "Install Ruby"
  task :install_ruby => :environment do
    queue! %[CONFIGURE_OPTS="--disable-install-doc" rbenv install "#{ruby_version}" --verbose]
  end

  desc "Set default Ruby version"
  task :set_default_ruby => :environment do
    queue! %[echo "#{ruby_version}" > .ruby-version]
  end

  desc "Setup defaults for Rubygems"
  task :setup_rubygems => :environment do
    queue! %[echo 'install: --no-rdoc --no-ri' >> .gemrc]
    queue! %[echo 'update:  --no-rdoc --no-ri' >> .gemrc]
  end

  desc "Setup defaults for Bundler"
  task :setup_bundler => :environment do
    queue! %[mkdir .bundle]
    queue! %[echo '---'                             >> .bundle/config]
    queue! %[NUMBER_CORES=$(grep -c processor /proc/cpuinfo)]
    queue! %[if [ $NUMBER_CORES -gt 1 ]; then ]
    queue! %[    NUMBER_CORES=$((NUMBER_CORES - 1))]
    queue! %[fi]
    queue! %[echo "BUNDLE_PATH_JOBS: '$NUMBER_CORES'"           >> .bundle/config]
    queue! %[echo "BUNDLE_PATH: 'vendor'"           >> .bundle/config]
    queue! %[echo "BUNDLE_DISABLE_SHARED_GEMS: '1'" >> .bundle/config]
  end

  desc "Setup defaults for IRB"
  task :setup_irb => :environment do
    queue! %[echo "require 'irb/ext/save-history'"                            >> .irbrc]
    queue! %[echo ""                                                          >> .irbrc]
    queue! %[echo "IRB.conf[:SAVE_HISTORY] = 100"                             >> .irbrc]
    queue! %[echo "IRB.conf[:HISTORY_FILE] = '~/.irb_history' >> .irbrc"]
  end

  desc "Install bundler gem"
  task :install_bundler => :environment do
    queue! %[gem install bundler]
  end
end

desc "Change host name"
task :hostname => :environment do
  hostname = domain.split('.')[0]
  queue! %[echo '#{hostname}' | sudo tee /etc/hostname]
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
    queue! %[sudo apt-get -y install nodejs]
  end

  desc "Install PostgreSQL"
  task :install_postgres => :environment do
    queue! %[sudo apt-get -y install postgresql postgresql-contrib]
    queue! %[sudo apt-get -y install libpq-dev] # dependency for pg gem
    queue! %[echo 'Remember to ssh in to set up Postgres user and create database...']
  end

  desc "Configure PostgreSQL"
  task :config_postgres => :environment do
    queue! %[sudo -u postgres psql -c \"CREATE USER #{app_name} WITH PASSWORD \'#{app_name}\';\"]
    queue! %[sudo -u postgres psql -c \"ALTER ROLE #{app_name} WITH CREATEDB;\"]
    queue! %[sudo -u postgres psql -c \"CREATE DATABASE #{app_name}_production OWNER #{app_name};\"]
  end

  desc "Install memcached"
  task :install_memcached => :environment do
    queue! %[sudo apt-get -y install memcached]
  end

  desc "Install redis"
  task :install_redis => :environment do
    queue! %[sudo apt-get -y install redis-server]
  end

  desc "Install nginx"
  task :install_nginx => :environment do
    queue! %[sudo apt-get -y install nginx]
  end

  desc "Configure Nginx"
  task :config_nginx => :environment do
    template_dir = File.expand_path('../../templates', __FILE__)
    nginx_template_location = template_dir + '/nginx_conf.erb'
    app_nginx_config = erb(nginx_template_location)
    queue! %[echo -n '#{app_nginx_config}' | sudo tee /etc/nginx/sites-available/#{app_name}]
    queue! %[sudo ln -s /etc/nginx/sites-available/#{app_name} /etc/nginx/sites-enabled/#{app_name}]
    queue! %[sudo service nginx restart]
  end

  desc "Install smem"
  task :install_smem => :environment do
    queue! %[sudo apt-get -y install smem]
  end
end
