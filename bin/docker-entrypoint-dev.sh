#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails
rm -f /rails/tmp/pids/server.pid

# Install missing gems and dependencies
bundle check || bundle install
yarn install --check-files

# Run pending migrations
bundle exec rails db:prepare

# Then exec the container's main process (what's set as CMD in the Dockerfile)
exec "$@" 