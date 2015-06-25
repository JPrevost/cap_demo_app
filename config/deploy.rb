# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'cap_demo_app'
set :repo_url, 'git@github.com:JPrevost/cap_demo_app.git'

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/local_env.rb')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5
set :rvm_ruby_version, 'ruby-2.1.3'

namespace :config do
  desc 'Create apache config file and add selinux context'
  task :vhost do
    on roles(:web) do
      vhost_config = StringIO.new(%{
LoadModule passenger_module /usr/local/rvm/gems/#{fetch(:rvm_ruby_version)}/gems/passenger-5.0.11/buildout/apache2/mod_passenger.so
   <IfModule mod_passenger.c>
     PassengerRoot /usr/local/rvm/gems/#{fetch(:rvm_ruby_version)}/gems/passenger-5.0.11
     PassengerDefaultRuby /usr/local/rvm/wrappers/#{fetch(:rvm_ruby_version)}/ruby
   </IfModule>

NameVirtualHost *:80
<VirtualHost *:80>
  PassengerRuby /usr/local/rvm/wrappers/#{fetch(:rvm_ruby_version)}/ruby
  PassengerFriendlyErrorPages off
  DocumentRoot #{fetch(:deploy_to)}/current/public
  RailsBaseURI /
  PassengerDebugLogFile /var/log/httpd/#{fetch(:application)}-passenger.log
  <Directory #{fetch(:deploy_to)}/current/public >
    Options -MultiViews
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript
    Order allow,deny
    Allow from all
  </Directory>
</VirtualHost>
      })
      tmp_file = "/tmp/#{fetch(:application)}.conf"
      httpd_file = "/etc/httpd/conf.d/#{fetch(:application)}.conf"
      upload! vhost_config, tmp_file
      execute :sudo, :mv, tmp_file, httpd_file
      execute :sudo, :chmod, "644", httpd_file
      #execute :sudo, :chcon, "-t", "httpd_config_t", httpd_file
    end
  end
end

namespace :deploy do

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
