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
set :linked_files, fetch(:linked_files, []).push('.env')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', '.eye')

# Default value for default_env is {}
set :default_env, { 'EYE_HOME' => "#{shared_path}" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# namespace :deploy do
#   desc 'Restart application'
#   task :restart do
#     on roles(:app) do
#       execute :leye, "--eyefile #{File.join(current_path, 'Eyefile')} restart all"
#       invoke 'puma:restart'
#     end
#   end

#   after :publishing, :restart

#   before :restart, :update_eye do
#     on roles(:app) do
#       execute :leye, "--eyefile #{File.join(current_path, 'Eyefile')} load"
#     end
#   end
# end

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before :start, :make_dirs
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
        puts "WARNING: HEAD is not the same as origin/master"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
      execute :leye, "--eyefile #{File.join(current_path, 'Eyefile')} load"
    end
  end

  before :starting,     :check_revision
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  after  :finishing,    :restart
end