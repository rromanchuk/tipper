Eye.application "tipper" do
  env 'RBENV_ROOT' => '/usr/local/rbenv', 'PATH' => "/usr/local/rbenv/shims:/usr/local/rbenv/bin:#{ENV['PATH']}"
  #working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))
  working_dir File.expand_path(File.join(File.dirname(__FILE__)))

  process "favorite_stream" do
    pid_file "tmp/pids/favorite_stream.pid"
    start_command "rails r lib/t.rb"
    daemonize true
    stdall "log/favorite_stream.log"
  end

  process "fetch_favorites" do
    pid_file "tmp/pids/fetch_favorites.pid"
    start_command "rails r lib/fetch_favorites_worker.rb"
    daemonize true
    stdall "log/fetch_favorites.log"
  end

  process "process_tips_worker" do
    pid_file "tmp/pids/process_tips_worker.pid"
    start_command "rails r lib/process_tips_worker.rb"
    daemonize true
    stdall "log/process_tips_worker.log"
  end

  process "process_wallet_notify_worker" do 
    pid_file "tmp/pids/process_wallet_notify_worker.pid"
    start_command "rails r lib/process_wallet_notify_worker.rb"
    daemonize true
    stdall "log/process_wallet_notify_worker.log"
  end
end