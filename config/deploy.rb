# config/deploy.rb — shared deployment configuration

set :application, "fleet_core_engine"
set :repo_url,    "https://github.com/kiburei/fleet_core_engine.git"

# Deploy from the main branch by default; override per stage
set :branch, ENV.fetch("BRANCH", "main")

# Deploy to /var/www/fleet_core_engine on the server
set :deploy_to, "/var/www/fleet_core_engine"

# Keep the last 5 releases
set :keep_releases, 5

# Linked files are symlinked into each release from the shared/ directory
append :linked_files,
  "config/master.key",
  "config/credentials.yml.enc",
  ".env"

# Linked directories are symlinked into each release from shared/
append :linked_dirs,
  "log",
  "tmp/pids",
  "tmp/cache",
  "tmp/sockets",
  "public/uploads",
  "storage"

# rvm — must match the Ruby version on the server
set :rvm_type,         :system          # :user if rvm is installed per-user (~/.rvm)
set :rvm_ruby_version, File.read(".ruby-version").strip rescue "3.3.0"

# Bundler
set :bundle_without,   %w[development test]
set :bundle_flags,     "--deployment --quiet"

# Assets (propshaft + jsbundling)
set :assets_roles, [:web]

# Puma
set :puma_bind,        "tcp://0.0.0.0:3000"
set :puma_state,       "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,         "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log,  "#{release_path}/log/puma.access.log"
set :puma_error_log,   "#{release_path}/log/puma.error.log"
set :puma_threads,     [0, 5]
set :puma_workers,     2
set :puma_worker_timeout, nil
set :puma_init_active_record, true

# Output format
set :format,        :airbrussh
set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
set :pty, false

# Git clone options
set :git_shallow_clone, 1

# Run migrations only when DB files changed
set :migration_role, :db

namespace :deploy do
  desc "Restart application (touch tmp/restart.txt for Puma plugin, or reload systemd service)"
  task :restart do
    on roles(:web), in: :sequence, wait: 5 do
      execute :touch, release_path.join("tmp/restart.txt")
    end
  end

  desc "Seed the database"
  task :seed do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "db:seed"
        end
      end
    end
  end

  after :publishing, :restart
  after :restart,    :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # execute :rake, "tmp:clear" if you want to clear tmp on each deploy
    end
  end
end
