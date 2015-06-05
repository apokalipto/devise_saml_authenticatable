def sh!(cmd)
  unless system(cmd)
    raise "[#{cmd}] failed with exit code #{$?.exitstatus}"
  end
end

def app_ready?(pid, port)
  Process.getpgid(pid) &&
    system("lsof -i:#{port}", out: '/dev/null')
end

def create_app(name)
  rails_new_options = "-T -J -S --skip-spring"
  rails_new_options << " -O" if name == 'idp'
  Bundler.with_clean_env do
    Dir.chdir(File.expand_path('../../support', __FILE__)) do
      FileUtils.rm_rf(name)
      sh! "rails new #{name} #{rails_new_options} -m #{name}_template.rb"
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

def stop_app(name, pid)
  if pid
    Process.kill(:TERM, pid)
    Process.wait(pid)
  end
end
