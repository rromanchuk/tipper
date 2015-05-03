Eye.application "rbenv_example" do
  env 'RBENV_ROOT' => '/usr/local/rbenv', 'PATH' => "/usr/local/rbenv/shims:/usr/local/rbenv/bin:#{ENV['PATH']}"
  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))

  process "process_tips_worker" do
    pid_file "process_tips_worker.pid"
    start_command "rails r lib/process_tips_worker.rb"
    daemonize true
    stdall "process_tips_worker.log"
  end
end