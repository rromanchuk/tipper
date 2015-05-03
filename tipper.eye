Eye.application "tipper" do
  env 'RBENV_ROOT' => '/usr/local/rbenv', 'PATH' => "/usr/local/rbenv/shims:/usr/local/rbenv/bin:#{ENV['PATH']}"
  #working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))
  #working_dir "/home/ec2-user/apps/tipper/shared/processes"

  process "favorite_stream" do
    pid_file "/home/ec2-user/apps/tipper/shared/processes/favorite_stream.pid"
    start_command "rails r /home/ec2-user/apps/tipper/current/lib/t.rb"
    daemonize true
    stdall "/home/ec2-user/apps/tipper/shared/processes/favorite_stream.log"
  end

  process "fetch_favorites" do
    pid_file "/home/ec2-user/apps/tipper/shared/processes/fetch_favorites.pid"
    start_command "rails r /home/ec2-user/apps/tipper/current/lib/fetch_favorites_worker.rb"
    daemonize true
    stdall "/home/ec2-user/apps/tipper/shared/processes/fetch_favorites.log"
  end

  process "process_tips_worker" do
    pid_file "/home/ec2-user/apps/tipper/shared/processes/process_tips_worker.pid"
    start_command "rails r /home/ec2-user/apps/tipper/current/lib/process_tips_worker.rb"
    daemonize true
    stdall "/home/ec2-user/apps/tipper/shared/processes/process_tips_worker.log"
  end
end