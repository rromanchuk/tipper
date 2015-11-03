lowlevel_error_handler do |e|
  Rollbar.critical(e)
  [500, {}, ["An error has occurred, and engineers have been informed. Please reload the page. If you continue to have problems, contact support@example.com\n"]]
end

if ENV['RAILS_ENV'] == 'production'
  directory "/home/ec2-user/apps/tipper/current"
  workers 2
  bind "unix:///home/ec2-user/apps/tipper/shared/tmp/sockets/puma.sock"
else
  workers 1
  port 9888
end

threads 1, 1

environment ENV['RAILS_ENV'] || 'development'

prune_bundler


