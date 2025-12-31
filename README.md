# Burrow - Systemd-based Infrastructure

Declarative infrastructure for VPS using systemd services instead of Docker.

## Services

- **Caddy** - Reverse proxy with automatic HTTPS (Let's Encrypt)
- **Gitea** - Git hosting at code.jakegoldsborough.com
- **Woodpecker CI** - Continuous integration at ci.jakegoldsborough.com
- **Scrob** - Music scrobbling server at scrob.jakegoldsborough.com
- **Scrob UI** - Web interface for Scrob at ui.scrob.jakegoldsborough.com
- **GoatCounter** (2 instances) - Analytics at:
  - stats.jakegoldsborough.com
  - stats.date-ver.com
- **PostgreSQL** - Database for Gitea, Woodpecker, and Scrob

## Architecture

Unlike the Docker version, this uses native systemd services:

- All services run directly on the host (no containers)
- PostgreSQL for Gitea, Woodpecker, and Scrob databases
- SQLite for GoatCounter instances (separate databases)
- Woodpecker uses local backend (no Docker required for builds)
- Scrob UI served as static files by Caddy
- Caddy handles reverse proxy and automatic SSL
- Configuration managed via git

## Prerequisites

- VPS with root access
- Arch Linux, Debian/Ubuntu, or Fedora/RHEL
- Domains pointing to your VPS:
  - code.jakegoldsborough.com
  - ci.jakegoldsborough.com
  - scrob.jakegoldsborough.com
  - ui.scrob.jakegoldsborough.com
  - stats.jakegoldsborough.com
  - stats.date-ver.com

## Directory Structure

```
burrow-systemd/
├── systemd/              # Systemd service files
│   ├── caddy.service
│   ├── gitea.service
│   ├── woodpecker-server.service
│   ├── woodpecker-agent.service
│   ├── scrob.service
│   ├── goatcounter-jg.service
│   └── goatcounter-dv.service
├── config/
│   ├── Caddyfile         # Reverse proxy config
│   ├── gitea/
│   │   └── app.ini       # Gitea configuration template
│   ├── woodpecker/
│   │   ├── server.env    # Woodpecker server config
│   │   └── agent.env     # Woodpecker agent config
│   ├── scrob/
│   │   └── scrob.env     # Scrob server config
│   └── postgres/
│       └── init-databases.sql  # PostgreSQL initialization
├── bin/
│   ├── bootstrap         # Initial setup script
│   ├── deploy            # Update and restart services
│   ├── backup            # Backup databases
│   ├── update            # Update service binaries
│   └── create-scrob-user # Create scrob user and get API token
├── data/                 # Local data (git-ignored)
│   ├── goatcounter-jg/
│   └── goatcounter-dv/
├── .env                  # Secrets (git-ignored)
└── .env.example          # Example environment file
```

## Installation

### 1. Clone this repository on your VPS

```bash
cd ~/dev
git clone <your-repo-url> burrow-systemd
cd burrow-systemd
```

### 2. Run bootstrap

This will:
- Install required packages (caddy, postgresql)
- Download Gitea and GoatCounter binaries
- Create system users and directories
- Initialize PostgreSQL
- Generate secure passwords
- Copy configuration files
- Install systemd services
- Migrate existing GoatCounter databases if found

```bash
sudo ./bin/bootstrap
```

### 3. Review the generated configuration

```bash
cat .env  # Check generated passwords
```

### 4. Deploy services

```bash
sudo ./bin/deploy
```

### 5. Verify services are running

```bash
systemctl status gitea caddy goatcounter-jg goatcounter-dv
```

Your services should now be available at:
- https://code.jakegoldsborough.com
- https://stats.jakegoldsborough.com
- https://stats.date-ver.com

## Setting Up Scrob

Scrob is a music scrobbling server with a REST API. After deployment, you'll need to create at least one user account.

### 1. Create Your First User

Use the `create-scrob-user` script to create a user and get an API token:

```bash
cd ~/dev/burrow-systemd
sudo ./bin/create-scrob-user <username> <password>
```

Example:
```bash
sudo ./bin/create-scrob-user jake mypassword
```

The script will:
1. Create the user in the scrob database
2. Log in via the API
3. Display your API token

### 2. Save Your API Token

Copy the displayed token and save it securely. You'll need it to use scrob clients like shelltrax:

```bash
export SCROB_TOKEN="your-token-here"
export SCROB_SERVER_URL="https://scrob.jakegoldsborough.com"
```

### 3. Access Scrob

- **API**: https://scrob.jakegoldsborough.com
- **Web UI**: https://ui.scrob.jakegoldsborough.com

Log in to the web UI with your username and password.

### 4. Create Additional Users (Optional)

Repeat the `create-scrob-user` command to create more users:

```bash
sudo ./bin/create-scrob-user alice alicespassword
sudo ./bin/create-scrob-user bob bobspassword
```

## Setting Up Woodpecker CI

Woodpecker CI requires OAuth integration with Gitea. Follow these steps:

### 1. Create OAuth Application in Gitea

1. Access Gitea at https://code.jakegoldsborough.com
2. Log in and go to **Settings** → **Applications**
3. Scroll to **Manage OAuth2 Applications**
4. Click **Create a new OAuth2 Application**
5. Fill in the details:
   - **Application Name**: `Woodpecker CI`
   - **Redirect URI**: `https://ci.jakegoldsborough.com/authorize`
6. Click **Create Application**
7. Copy the **Client ID** and **Client Secret**

### 2. Configure Woodpecker

Edit the `.env` file and add the OAuth credentials:

```bash
cd ~/dev/burrow-systemd
nano .env
```

Add or update these lines:

```bash
GITEA_OAUTH_CLIENT_ID=<your-client-id>
GITEA_OAUTH_CLIENT_SECRET=<your-client-secret>
```

### 3. Start Woodpecker Services

```bash
sudo ./bin/deploy
```

The deploy script will detect the OAuth configuration and start Woodpecker automatically.

### 4. Access Woodpecker CI

Visit https://ci.jakegoldsborough.com and log in with your Gitea account. Woodpecker will automatically sync your repositories.

### 5. Configure Admin User (Optional)

To make yourself an admin, edit `config/woodpecker/server.env` and add your Gitea username:

```bash
WOODPECKER_ADMIN=your-username
```

Then redeploy:

```bash
sudo ./bin/deploy
```

## Deployment Workflow

After making changes to configuration:

```bash
# 1. Make changes locally
vim config/Caddyfile

# 2. Commit to git
git add .
git commit -m "Update Caddyfile"
git push

# 3. On VPS, pull changes
cd ~/dev/burrow-systemd
git pull

# 4. Deploy (updates config and restarts services)
sudo ./bin/deploy
```

## Backup

Create a backup of all databases and data:

```bash
sudo ./bin/backup
```

This backs up:
- PostgreSQL databases (Gitea, Woodpecker, Scrob)
- GoatCounter SQLite databases
- Gitea repositories and data
- Configuration files

Backups are stored in `~/burrow-backups/` with timestamps.

## Service Management

### View logs

```bash
# All services
journalctl -u gitea -u caddy -u scrob -u goatcounter-jg -u goatcounter-dv -u woodpecker-server -u woodpecker-agent -f

# Individual service
journalctl -u gitea -f
journalctl -u caddy -f
journalctl -u scrob -f
journalctl -u woodpecker-server -f
journalctl -u woodpecker-agent -f
```

### Restart a service

```bash
sudo systemctl restart gitea
sudo systemctl restart caddy
sudo systemctl restart scrob
sudo systemctl restart woodpecker-server woodpecker-agent
```

### Stop all services

```bash
sudo systemctl stop gitea caddy scrob goatcounter-jg goatcounter-dv woodpecker-server woodpecker-agent
```

### Start all services

```bash
sudo systemctl start postgresql gitea scrob goatcounter-jg goatcounter-dv woodpecker-server woodpecker-agent caddy
```

## File Locations

- Gitea data: `/var/lib/gitea/`
- Gitea config: `/etc/gitea/app.ini`
- Woodpecker data: `/var/lib/woodpecker/`
- Woodpecker config: `/etc/woodpecker/server.env` and `/etc/woodpecker/agent.env`
- Scrob data: `/var/lib/scrob/`
- Scrob config: `/etc/scrob/scrob.env`
- Scrob UI: `/var/www/scrob-ui/`
- GoatCounter data: `/var/lib/goatcounter-jg/` and `/var/lib/goatcounter-dv/`
- Caddy config: `/etc/caddy/Caddyfile`
- Systemd services: `/etc/systemd/system/*.service`
- PostgreSQL data: `/var/lib/postgres/data`

## Troubleshooting

### Services won't start

Check logs:
```bash
journalctl -u <service-name> -n 50
```

### Port conflicts

Check what's using a port:
```bash
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
sudo netstat -tlnp | grep :3000
```

### PostgreSQL connection issues

Check if PostgreSQL is running:
```bash
systemctl status postgresql
```

Test connection:
```bash
sudo -u postgres psql -c "\l"
```

### Caddy certificate issues

Check Caddy logs:
```bash
journalctl -u caddy -f
```

Make sure ports 80 and 443 are open and domains are pointing to your VPS.

## Security Notes

- `.env` file contains sensitive credentials - keep it secure and backed up
- All services run as dedicated users with limited permissions
- Caddy handles automatic HTTPS with Let's Encrypt
- PostgreSQL is only accessible locally (not exposed to internet)
- GoatCounter instances run on localhost and are proxied through Caddy

## Differences from Docker Version

**Advantages:**
- No Docker networking issues
- Direct systemd integration
- Easier log access via journalctl
- Services use system package manager where possible
- Lower memory overhead

**Disadvantages:**
- Binaries must be manually updated
- Service isolation is handled by systemd users, not containers
- Can't easily move to a different host

## Updates

### Update Gitea

```bash
# Download new version
wget -O /usr/local/bin/gitea https://dl.gitea.com/gitea/<VERSION>/gitea-<VERSION>-linux-amd64
chmod +x /usr/local/bin/gitea

# Restart service
sudo systemctl restart gitea
```

### Update GoatCounter

```bash
# Download new version
wget -O /tmp/goatcounter.gz https://github.com/arp242/goatcounter/releases/download/<VERSION>/goatcounter-<VERSION>-linux-amd64.gz
gunzip /tmp/goatcounter.gz
sudo mv /tmp/goatcounter /usr/local/bin/goatcounter
sudo chmod +x /usr/local/bin/goatcounter

# Restart services
sudo systemctl restart goatcounter-jg goatcounter-dv
```

### Update Scrob

```bash
# Download new version
wget -O /usr/local/bin/scrob https://github.com/ducks/scrob/releases/download/v<VERSION>/scrob-linux-x86_64
chmod +x /usr/local/bin/scrob

# Restart service
sudo systemctl restart scrob
```

### Update Scrob UI

```bash
# Download new version
wget -O /tmp/scrob-ui-dist.tar.gz https://github.com/ducks/scrob-ui/releases/download/v<VERSION>/scrob-ui-dist.tar.gz
tar -xzf /tmp/scrob-ui-dist.tar.gz -C /var/www/scrob-ui
rm /tmp/scrob-ui-dist.tar.gz

# No restart needed - served as static files by Caddy
```

### Update Woodpecker

```bash
# Download new version
wget -O /tmp/woodpecker-server https://github.com/woodpecker-ci/woodpecker/releases/download/v<VERSION>/woodpecker-server_linux_amd64
wget -O /tmp/woodpecker-agent https://github.com/woodpecker-ci/woodpecker/releases/download/v<VERSION>/woodpecker-agent_linux_amd64
sudo mv /tmp/woodpecker-server /usr/local/bin/woodpecker-server
sudo mv /tmp/woodpecker-agent /usr/local/bin/woodpecker-agent
sudo chmod +x /usr/local/bin/woodpecker-server /usr/local/bin/woodpecker-agent

# Restart services
sudo systemctl restart woodpecker-server woodpecker-agent
```

Alternatively, use the update script:

```bash
sudo ./bin/update woodpecker
# or update all services
sudo ./bin/update all
```

### Update Caddy

```bash
# Using package manager
sudo pacman -Syu caddy  # Arch
sudo apt-get update && sudo apt-get upgrade caddy  # Debian/Ubuntu

sudo systemctl restart caddy
```
