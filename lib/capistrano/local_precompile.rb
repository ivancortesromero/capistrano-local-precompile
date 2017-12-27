require 'capistrano/rails/assets'

namespace :load do
  task :defaults do
    set :precompile_env,   fetch(:rails_env) || 'production'
    set :assets_dir,       "public/assets"
    set :packs_dir,        "public/packs"    
    set :rsync_cmd,        "rsync -av --delete"
    set :user,             ENV['DEPLOY_USER'] || 'deploy'
    set :host,             ENV.fetch('DEPLOY_HOST')

    after "bundler:install", "deploy:assets:prepare"
    after "deploy:assets:prepare", "deploy:assets:compile"
    after "deploy:assets:compile", "deploy:assets:clup"
  end
end

namespace :deploy do
  Rake::Task["deploy:compile_assets"].clear

  namespace :assets do
    desc "Actually precompile the assets locally"
    task :prepare do
      run_locally do
        with rails_env: fetch(:precompile_env) do
          execute "rake assets:clean"
          execute "rake assets:precompile"
        end
      end
    end

    desc "Performs rsync to app servers"
    task :compile do
      run_locally do
        execute "#{fetch(:rsync_cmd)} ./#{fetch(:assets_dir)}/ #{fetch(:user)}@#{fetch(:host)}:#{release_path}/#{fetch(:assets_dir)}/"
        execute  "#{fetch(:rsync_cmd)} ./#{fetch(:packs_dir)}/ #{fetch(:user)}@#{fetch(:host)}:#{release_path}/#{fetch(:packs_dir)}/"
      end
    end

    desc "Remove all local precompiled assets"
    task :clup do
      run_locally do
        with rails_env: fetch(:precompile_env) do
          execute "rm -rf", fetch(:assets_dir)
          execute "rm -rf", fetch(:packs_dir)
        end
      end
    end
  end
end
