# frozen_string_literal: true

require 'stringio'
lock '~> 3.19.2'

set :application, 'rma.webgate.pro'
set :ssh_options, { forward_agent: true, port: 39_168 }
set :repo_url, 'git@github.com:WebgateSystems/akademy2.git'
set :repository_cache, 'git_cache'
set :deploy_via, :remote_cache
set :bundle_without, %w[test development].join(':')
set :pty, true

set :log_level, :info
set :format, :pretty
set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto

set :linked_files,
    %W[config/cable.yml config/settings/#{fetch(:stage)}.yml public/robots.txt]
set :linked_dirs, %w[log public/uploads tmp]

set :keep_releases, 5

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

namespace :deploy do
  task :restart do
    on roles(:web) do
      execute("~#{fetch(:deploy_user)}/bin/#{fetch(:stage)}.sh", :restart)
    end
  end
end

namespace :npm do
  task :install do
    on roles(:web) do
      within release_path do
        execute :bash, '-lc', 'NPM_CONFIG_PRODUCTION=false npm ci --no-audit --no-fund'
      end
    end
  end

  task :build do
    on roles(:web) do
      within release_path do
        execute :npm, 'run build:css'
        execute :npm, 'run build'
      end
    end
  end
end

before 'deploy:assets:precompile', 'npm:install'
before 'deploy:assets:precompile', 'npm:build'
