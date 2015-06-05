def sh!(cmd)
  unless system(cmd)
    raise "[#{cmd}] failed with exit code #{$?.exitstatus}"
  end
end

def create_app(name)
  rails_new_options = "-T -J -S --skip-spring"
  Bundler.with_clean_env do
    Dir.chdir(File.expand_path('../../support', __FILE__)) do
      FileUtils.rm_rf(name)
      sh! "rails new #{name} #{rails_new_options} -m #{name}_template.rb"
    end
  end
end
