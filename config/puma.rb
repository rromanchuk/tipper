if ENV['RAILS_ENV'] == 'production'
  directory '/home/ec2-user/apps/tipper/current'
  workers 2
else
  workers 1
end

threads 1, 1

environment ENV['RAILS_ENV'] || 'development'

port 7890

prune_bundler
