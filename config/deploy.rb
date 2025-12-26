# frozen_string_literal: true

require 'stringio'
lock '~> 3.19.2'

set :ssh_options, { forward_agent: true, port: 39_168 }
set :repo_url, 'git@github.com:WebgateSystems/akademy2.git'
set :repository_cache, 'git_cache'
set :deploy_via, :remote_cache
set :bundle_without, %w[test development].join(':')
set :pty, true

# NVM / Node
set :nvm_type, :user
set :nvm_node, 'v22.19.0'
# yarn nie mapujemy, bo Yarn 3 jest uruchamiany przez corepack (shim), a nie globalny bin
set :nvm_map_bins, %w[node npm]

# Yarn version required by project (must match package.json "packageManager")
set :yarn_version, '3.2.0'

set :log_level, :info
set :format, :pretty
set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto

set :linked_files,
    %W[config/cable.yml config/settings/#{fetch(:stage)}.yml public/robots.txt]
set :linked_dirs, %w[log public/uploads public/generated tmp]

set :keep_releases, 5

# ---- Hooks ----
before 'deploy:assets:precompile', 'node:corepack_prepare'
before 'deploy:assets:precompile', 'node:yarn_install'
before 'deploy:assets:precompile', 'node:build'

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

# ---- Node/Yarn tasks ----
namespace :node do
  # Pomocniczo: zawsze uruchamiamy komendy z poprawnym PATH do nvm node
  def with_nvm_path(&block)
    nvm_bin_path = "$HOME/.nvm/versions/node/#{fetch(:nvm_node)}/bin"
    with path: "#{nvm_bin_path}:$PATH", &block
  end

  desc 'Enable corepack and activate required Yarn version'
  task :corepack_prepare do
    on roles(:web) do
      within release_path do
        with_nvm_path do
          # corepack enable jest idempotentne; jak już jest, nic nie popsuje
          execute :corepack, 'enable'
          # Aktywujemy konkretną wersję Yarn dla usera (w ramach tego Node z nvm)
          execute :corepack, "prepare yarn@#{fetch(:yarn_version)} --activate"
          # Szybki sanity-check do logów (ułatwia debug)
          execute :yarn, '--version'
        end
      end
    end
  end

  desc 'Install JS dependencies with Yarn (Yarn 3 via Corepack)'
  task :yarn_install do
    on roles(:web) do
      within release_path do
        with_nvm_path do
          # Jeśli projekt używa node_modules linker:
          # - usuwamy node_modules aby uniknąć śmieci między deployami.
          # Jeśli używasz PnP, ta linia jest zbędna, ale też nie szkodzi.
          execute :rm, '-rf', 'node_modules'

          # Zalecane na deployu/CI:
          # --immutable: fail jeśli lockfile nie pasuje
          # Jeśli czasem generujesz lock na serwerze (nie polecam), zmień na zwykłe `yarn install`.
          execute :yarn, 'install --immutable'
        end
      end
    end
  end

  desc 'Build frontend assets'
  task :build do
    on roles(:web) do
      within release_path do
        with_nvm_path do
          execute :npm, 'run build'
          execute :npm, 'run build:css'
        end
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
