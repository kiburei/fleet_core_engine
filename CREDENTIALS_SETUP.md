# Credentials Setup for Fleet Core Engine

This document explains how to manage Rails credentials for persistent deployment using Kamal.

## Overview

The application is configured to use persistent credentials that survive deployments. The credentials are stored on the server and mapped into the Docker containers.

## Initial Setup (Already Done)

The initial setup has been completed. The following files have been created:

- `/home/rails/fleet_core_engine/config/master.key` - Master key for decrypting credentials
- `/home/rails/fleet_core_engine/config/credentials.yml.enc` - Encrypted credentials file

## Deployment Methods

### Method 1: Using the Deploy Script (Recommended)

```bash
./bin/deploy_with_credentials
```

This script:
1. Ensures credentials exist on the server
2. Deploys the application
3. Verifies the deployment

### Method 2: Standard Kamal Deploy

```bash
bundle exec kamal deploy
```

This will work now that the credentials are properly configured.

## Managing Credentials

### Viewing Current Credentials

SSH to the server and view credentials:

```bash
ssh root@fleet.matean.online
cd /home/rails/fleet_core_engine
RAILS_MASTER_KEY=$(cat config/master.key) rails credentials:show
```

### Editing Credentials

SSH to the server and edit credentials:

```bash
ssh root@fleet.matean.online
cd /home/rails/fleet_core_engine
EDITOR=nano rails credentials:edit
```

### From Local Machine

You can also edit credentials locally and they will be deployed:

```bash
EDITOR=nano rails credentials:edit
```

Then deploy with:

```bash
./bin/deploy_with_credentials
```

## File Structure

### On Server (`/home/rails/fleet_core_engine/config/`)
```
config/
├── master.key (600 permissions)
└── credentials.yml.enc (600 permissions)
```

### In Docker Container (`/rails/config/`)
```
config/
├── master.key (mapped from server)
└── credentials.yml.enc (mapped from server)
```

## Configuration Details

### Kamal Configuration (`config/deploy.yml`)

The following configuration ensures credentials persist:

```yaml
# Map files from host to container
files:
  - "/home/rails/fleet_core_engine/config/master.key:/rails/config/master.key"
  - "/home/rails/fleet_core_engine/config/credentials.yml.enc:/rails/config/credentials.yml.enc"

# Environment variables
env:
  secret:
    - RAILS_MASTER_KEY
```

### Scripts Available

1. `./bin/setup_server_credentials` - One-time setup (already run)
2. `./bin/deploy_with_credentials` - Deploy with credential checks
3. `./bin/setup_credentials` - Server-side setup script

## Troubleshooting

### If Credentials Are Missing After Deployment

1. Check if files exist on server:
   ```bash
   ssh root@fleet.matean.online "ls -la /home/rails/fleet_core_engine/config/"
   ```

2. Run the setup script again:
   ```bash
   ./bin/setup_server_credentials
   ```

3. Verify in container:
   ```bash
   bundle exec kamal app exec "ls -la /rails/config/"
   ```

### If Rails Can't Decrypt Credentials

1. Check master key permissions:
   ```bash
   ssh root@fleet.matean.online "ls -la /home/rails/fleet_core_engine/config/master.key"
   ```

2. Verify master key content:
   ```bash
   ssh root@fleet.matean.online "cat /home/rails/fleet_core_engine/config/master.key"
   ```

3. Compare with local master key:
   ```bash
   cat config/master.key
   ```

### If Deployment Fails

1. Check Kamal logs:
   ```bash
   bundle exec kamal logs -f
   ```

2. Check server connectivity:
   ```bash
   ssh root@fleet.matean.online "echo 'Connection OK'"
   ```

3. Verify Docker is running:
   ```bash
   ssh root@fleet.matean.online "docker ps"
   ```

## Best Practices

1. **Never commit credentials to git** - They're encrypted but still shouldn't be in version control
2. **Keep master.key secure** - This is the key to decrypt all credentials
3. **Use the deploy script** - It includes verification steps
4. **Backup credentials** - Store them securely offline
5. **Regular updates** - Update credentials periodically for security

## Security Notes

- The master key is stored on the server with 600 permissions (readable only by owner)
- Credentials are encrypted at rest
- File mappings ensure credentials are available to the application
- Environment variables are injected securely through Kamal

## Server Information

- **Server**: fleet.matean.online
- **SSH User**: root
- **App Path**: /home/rails/fleet_core_engine
- **Deployment Tool**: Kamal
