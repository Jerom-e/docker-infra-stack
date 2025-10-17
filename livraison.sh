#!/usr/bin/env bash
# livraison.sh -- Install Docker + Compose plugin (on Debian 12/13) and deploy stacks.
# Usage: sudo ./livraison.sh [--no-start]
set -euo pipefail
NO_START=false
if [ "${1:-}" = "--no-start" ]; then
  NO_START=true
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (sudo)." >&2
  exit 2
fi

echo "Updating apt and installing prerequisites..."
apt update
apt install -y ca-certificates curl gnupg lsb-release

echo "Installing Docker (using official convenience script)..."
# Using get.docker.com convenience script for Debian 12/13 compatibility.
# If you prefer to use distribution packages or a pinned repo, replace this section.
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh

echo "Trying to install docker-compose plugin (if available via apt)..."
if apt-cache show docker-compose-plugin >/dev/null 2>&1; then
  apt update
  apt install -y docker-compose-plugin
else
  echo "docker-compose-plugin not found in apt. Docker may include compose as 'docker compose'."
fi

echo "Adding current user to docker group (if invoked with SUDO_USER)..."
if [ -n "${SUDO_USER:-}" ]; then
  usermod -aG docker "${SUDO_USER}"
  echo "User ${SUDO_USER} added to docker group. They may need to re-login."
fi

echo "Creating Docker network 'infra-net' if it does not exist..."
if ! docker network ls --format '{{.Name}}' | grep -q '^infra-net$'; then
  docker network create infra-net || true
fi

# Deploy stacks in order: monitoring → administration → development → production
deploy_stack() {
  local dir="$1"
  echo
  echo "---- Deploying stack in ${dir} ----"
  pushd "${dir}" >/dev/null
  if [ "$NO_START" = true ]; then
    echo "Skipping 'docker compose up' because --no-start was provided."
  else
    # Use 'docker compose' (compose plugin). If not present, fall back to 'docker-compose' if installed.
    if command -v docker >/dev/null && docker compose version >/dev/null 2>&1; then
      docker compose up -d
    elif command -v docker-compose >/dev/null; then
      docker-compose up -d
    else
      echo "No compose command found (neither 'docker compose' nor 'docker-compose')." >&2
      popd >/dev/null
      return 1
    fi
  fi
  popd >/dev/null
}

# Order
deploy_stack "monitoring"
#deploy_stack "administration"
#deploy_stack "developpement"
deploy_stack "production"

echo
echo "All done. Use 'docker ps' to see running containers."
echo "If you added a user to the docker group, they may need to log out and log in again."
