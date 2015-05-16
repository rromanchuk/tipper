# config valid only for current version of Capistrano

lock '3.4.0'

set :application, 'tipper'
set :repo_url, 'git@github.com:rromanchuk/tipper.git'

# Deploy current branch.
set :branch, `git rev-parse --abbrev-ref HEAD`.chomp

set :deploy_to, "/home/ec2-user/apps/tipper"

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# rbenv
set :rbenv_type, :user
set :rbenv_ruby, '2.2.2'
set :rbenv_map_bins, %w{rake gem bundle ruby rails leye}

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', '.eye')

# Default value for default_env is {}
set :default_env, { 'EYE_HOME' => "#{shared_path}" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app) do
      execute :leye, "--eyefile #{File.join(current_path, 'Eyefile')} restart all"
    end
  end

  after :publishing, :restart

  before :restart, :update_eye do
    on roles(:app) do
      execute :leye, "--eyefile #{File.join(current_path, 'Eyefile')} load"
    end
  end
end
