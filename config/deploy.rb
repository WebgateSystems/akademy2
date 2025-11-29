# frozen_string_literal: true

require 'stringio'
lock '~> 3.19.2'

set :ssh_options, { forward_agent: true, port: 39_168 }
set :repo_url, 'git@github.com:WebgateSystems/akademy2.git'
set :repository_cache, 'git_cache'
set :deploy_via, :remote_cache
set :bundle_without, %w[test development].join(':')
set :pty, true

set :nvm_type, :user
set :nvm_node, 'v22.19.0'
set :nvm_map_bins, %w[node npm yarn]

set :log_level, :info
set :format, :pretty
set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto

set :linked_files,
    %W[config/cable.yml config/settings/#{fetch(:stage)}.yml public/robots.txt]
set :linked_dirs, %w[log public/uploads tmp]

set :keep_releases, 5

before 'deploy:assets:precompile', 'npm:install'
before 'deploy:assets:precompile', 'npm:build'
after 'deploy:cleanup', 'deploy:restart'

desc 'Invoke a rake command on the remote server' # example: cap staging "invoke[db:seed]"
task :invoke, [:command] => 'deploy:set_rails_env' do |_task, args|
  on primary(:app) do
    within current_path do
      with rails_env: fetch(:rails_env) do
        rake args[:command]
      end
    end
  end
end

namespace :npm do
  task :install do
    on roles(:web) do
      within release_path do
        execute :rm, '-rf', 'node_modules'
        execute :yarn, 'install'
      end
    end
  end

  task :build do
    on roles(:web) do
      within release_path do
        execute :npm, 'run build'
        execute :npm, 'run build:css'
      end
    end
  end
end

namespace :deploy do
  task :restart do
    on roles(:web) do
      execute("~#{fetch(:deploy_user)}/bin/#{fetch(:stage)}.sh", :restart)
    end
  end

  namespace :assets do
    Rake::Task['precompile'].clear_actions

    desc 'Precompile assets'
    task :precompile do
      on roles(:web) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            nvm_bin_path = "$HOME/.nvm/versions/node/#{fetch(:nvm_node)}/bin"
            with path: "#{nvm_bin_path}:$PATH" do
              rake 'assets:precompile'
            end
          end
        end
      end
    end
  end
end
