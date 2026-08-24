#!/bin/sh
set -eu

remote=ubuntu@192.168.1.110
destination=/mnt/pve/hdd4tb/k3s-backups
identity=/root/.ssh/id_ed25519

umask 077
mkdir -p "$destination"

ssh -i "$identity" -o BatchMode=yes "$remote" 'sudo systemctl start k3s-datastore-backup.service'
latest=$(ssh -i "$identity" -o BatchMode=yes "$remote" "sudo sh -c 'ls -1t /var/backups/k3s/k3s-datastore-*.tar.gz | head -1'")
name=$(basename "$latest")

ssh -i "$identity" -o BatchMode=yes "$remote" "sudo cat '$latest'" > "$destination/$name"
ssh -i "$identity" -o BatchMode=yes "$remote" "sudo cat '$latest.sha256'" > "$destination/$name.sha256"

sed -i "s#  $latest#  $destination/$name#" "$destination/$name.sha256"
sha256sum -c "$destination/$name.sha256"

# Keep 30 days on the second physical host.
find "$destination" -maxdepth 1 -type f -name 'k3s-datastore-*.tar.gz*' -mtime +30 -delete
