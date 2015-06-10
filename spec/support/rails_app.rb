require 'open3'

def sh!(cmd)
  unless system(cmd)
    raise "[#{cmd}] failed with exit code #{$?.exitstatus}"
  end
end

def app_ready?(pid, port)
  Process.getpgid(pid) &&
    system("lsof -i:#{port}", out: '/dev/null')
end

def create_app(name, answers = [])
  rails_new_options = %w(-T -J -S --skip-spring)
  rails_new_options << "-O" if name == 'idp'
  Bundler.with_clean_env do
    Dir.chdir(File.expand_path('../../support', __FILE__)) do
      FileUtils.rm_rf(name)
      Open3.popen3("rails", "new", name, *rails_new_options, "-m", "#{name}_template.rb") do |stdin, stdout, stderr, wait_thread|
        while answers.any?
          question = stdout.gets
          answer = answers.shift
          stdin.puts answer
          $stdout.puts "#{question} #{answer}"
        end
        wait_thread.join

        $stdout.puts stdout.read
        $stderr.puts stderr.read
      end
    end
  end
end

def start_app(name, port, options = {})
  pid = nil
  Bundler.with_clean_env do
    Dir.chdir(File.expand_path("../../support/#{name}", __FILE__)) do
      pid = Process.spawn("bundle exec rails server -p #{port}")
      sleep 1 until app_ready?(pid, port)
      if app_ready?(pid, port)
        puts "Launched #{name} on port #{port} (pid #{pid})..."
      else
        raise "#{name} failed to start"
      end
    end
  end
  pid
end

def stop_app(pid)
  if pid
    Process.kill(:INT, pid)
    Process.wait(pid)
  end
end
