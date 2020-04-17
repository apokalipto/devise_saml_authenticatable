require 'open3'
require 'socket'
require 'timeout'

APP_READY_TIMEOUT ||= 30

def sh!(cmd)
  unless system(cmd)
    raise "[#{cmd}] failed with exit code #{$?.exitstatus}"
  end
end

def app_ready?(pid, port)
  Process.getpgid(pid) && port_open?(port)
rescue Errno::ESRCH
  false
end

def create_app(name, env = {})
  rails_new_options = %w(-T -J -S --skip-spring --skip-listen --skip-bootsnap)
  rails_new_options << "-O" if name == 'idp'
  with_clean_env do
    Dir.chdir(File.expand_path('../../support', __FILE__)) do
      FileUtils.rm_rf(name)
      system(env, "rails", "_#{Rails.version}_", "new", name, *rails_new_options, "-m", "#{name}_template.rb")
    end
  end
end

def start_app(name, port, options = {})
  pid = nil
  with_clean_env do
    from_app_dir(name) do
      pid = Process.spawn({"RAILS_ENV" => "production"}, "bundle exec rails server -p #{port} -e production", out: "log/#{name}.log", err: "log/#{name}.err.log")
      begin
        Timeout::timeout(APP_READY_TIMEOUT) do
          sleep 1 until app_ready?(pid, port)
        end
        if app_ready?(pid, port)
          puts "Launched #{name} on port #{port} (pid #{pid})..."
        else
          raise "#{name} failed after starting"
        end
      rescue Timeout::Error
        raise "#{name} failed to start"
      end
    end
  end
  pid
rescue RuntimeError => e
  $stdout.puts "#{File.read(File.expand_path("../../support/#{name}/log/#{name}.log", __FILE__))}"
  $stderr.puts "#{File.read(File.expand_path("../../support/#{name}/log/#{name}.err.log", __FILE__))}"
  raise e
end

def stop_app(pid)
  if pid
    Process.kill(:INT, pid)
    Process.wait(pid)
  end
end

def port_open?(port)
  Timeout::timeout(1) do
    begin
      s = TCPSocket.new('localhost', port)
      s.close
      return true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      # try 127.0.0.1
    end
    begin
      s = TCPSocket.new('127.0.0.1', port)
      s.close
      return true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      return false
    end
  end
rescue Timeout::Error
  false
end

def from_app_dir(name, &blk)
  Dir.chdir(File.expand_path("../../support/#{name}", __FILE__), &blk)
end

def with_clean_env(&blk)
  if Bundler.respond_to?(:with_original_env)
    Bundler.with_original_env(&blk)
  else
    Bundler.with_clean_env(&blk)
  end
end
