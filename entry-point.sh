#!/bin/bash
# Tim H 2023

# Install API keys for theHarvester and recon-ng

# do this on every boot

echo "Running discover's update"
cd /opt/discover || exit
git pull
./update.sh

if [[ -f /usr/share/recon-ng/recon-ng-install-api-keys.rec ]]; then 
    echo "Installing recon-ng keys..."
    /usr/bin/recon-ng -r /usr/share/recon-ng/recon-ng-install-api-keys.rec
else
    echo "file not found prob b/c you didn't bind mount it: /usr/share/recon-ng/recon-ng-install-api-keys.rec"
fi

# keep the stargate open
while true; do
  sleep 100000
done
