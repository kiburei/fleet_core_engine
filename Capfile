# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

# Load the SCM plugin appropriate to your project:
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Bundler
require "capistrano/bundler"

# Rails tasks (assets, migrations)
require "capistrano/rails/assets"
require "capistrano/rails/migrations"

# rbenv
require "capistrano/rbenv"

# Puma
require "capistrano/puma"
install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd

# Yarn (JS bundling)
require "capistrano/yarn"

# Load custom tasks from `lib/capistrano/tasks` if you create any, e.g.:
# Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
