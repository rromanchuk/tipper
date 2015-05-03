Eye.application "rbenv_example" do
  env 'RBENV_ROOT' => '/usr/local/rbenv', 'PATH' => "/usr/local/rbenv/shims:/usr/local/rbenv/bin:#{ENV['PATH']}"
  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))

  process "favorite_stream" do
    pid_file "favorite_stream.pid"
    start_command "rails r lib/t.rb"
    daemonize true
    stdall "favorite_stream.log"
  end

  process "fetch_favorites" do
    pid_file "fetch_favorites.pid"
    start_command "rails r lib/fetch_favorites_worker.rb"
    daemonize true
    stdall "fetch_favorites.log"
  end

  process "process_tips_worker" do
    pid_file "process_tips_worker.pid"
    start_command "rails r lib/process_tips_worker.rb"
    daemonize true
    stdall "process_tips_worker.log"
  end
end