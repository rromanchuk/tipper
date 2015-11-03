Eye.application "tipper" do
  env "RBENV_ROOT" => "/home/ec2-user/.rbenv", "RBENV_VERSION" => "2.2.2", "RAILS_ENV" => "production"
  working_dir "/home/ec2-user/apps/tipper/current"

  stdall "log/trash.log"

  # process :puma do
  #   pid_file "tmp/pids/puma.pid"
  #   stdall "log/puma.log"
  #   daemonize true
  #   start_command "rbenv exec bundle exec puma -C config/puma.rb"
  #   restart_command "kill -USR1 {PID}"
  #   stop_signals [:TERM, 5.seconds, :KILL]
  # end

  # process "favorite_stream_new" do
  #   pid_file "tmp/pids/favorite_stream_new.pid"
  #   start_command "bundle exec rails r lib/twitter_streamer.rb"
  #   daemonize true
  #   stdall "log/favorite_stream_new.log"
  # end

  process "favorite_poller" do
    pid_file "tmp/pids/favorite_poller.pid"
    start_command "bundle exec rails r lib/twitter_poller.rb"
    daemonize true
    stdall "log/favorite_poller.log"
  end

  process "fetch_favorites" do
    pid_file "tmp/pids/fetch_favorites.pid"
    start_command "bundle exec rails r lib/fetch_favorites_worker.rb"
    daemonize true
    stdall "log/fetch_favorites.log"
  end

  process "process_tips_worker" do
    pid_file "tmp/pids/process_tips_worker.pid"
    start_command "bundle exec rails r lib/process_tips_worker.rb"
    daemonize true
    stdall "log/process_tips_worker.log"
  end

  process "process_wallet_notify_worker" do
    pid_file "tmp/pids/process_wallet_notify_worker.pid"
    start_command "bundle exec rails r lib/process_wallet_notify_worker.rb"
    daemonize true
    stdall "log/process_wallet_notify_worker.log"
  end

   process "process_withdraw_balance_worker" do
    pid_file "tmp/pids/process_withdraw_balance_worker.pid"
    start_command "bundle exec rails r lib/process_withdraw_balance_worker.rb"
    daemonize true
    stdall "log/process_withdraw_balance_worker.log"
  end

  process "process_fund_worker" do
    pid_file "tmp/pids/process_fund_worker.pid"
    start_command "bundle exec rails r lib/process_fund_worker.rb"
    daemonize true
    stdall "log/process_fund_worker.log"
  end
end