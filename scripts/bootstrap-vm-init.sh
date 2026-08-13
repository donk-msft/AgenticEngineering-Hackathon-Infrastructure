#!/usr/bin/env bash
#
# Cloud-init for the private bootstrap VM. It installs only the command-line
# dependencies required by bootstrap-ticketing-database.sh; authentication is
# deliberately interactive and uses the SQL administrator's Entra identity.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release software-properties-common

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor --yes --output /usr/share/keyrings/microsoft-prod.gpg

curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/prod.list \
  | sed 's#^deb #deb [signed-by=/usr/share/keyrings/microsoft-prod.gpg] #' \
  > /etc/apt/sources.list.d/microsoft-prod.list

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/azure-cli.list

apt-get update
apt-get install -y azure-cli sqlcmd
