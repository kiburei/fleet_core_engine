# config/deploy/production.rb

server "178.62.101.24",
  user:  "deploy",
  roles: %w[web app db],
  ssh_options: {
    keys:            %w[~/.ssh/id_rsa],
    forward_agent:   true,
    auth_methods:    %w[publickey]
  }

set :rails_env, "production"
