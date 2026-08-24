#!/bin/sh
set -eu

backup_root=/var/backups/k3s
database=/var/lib/rancher/k3s/server/db/state.db
server_token=/var/lib/rancher/k3s/server/token
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
archive="$backup_root/k3s-datastore-$timestamp.tar.gz"

umask 077
mkdir -p "$backup_root"
workdir=$(mktemp -d "$backup_root/.backup.XXXXXX")

cleanup() {
    rm -rf "$workdir"
}
trap cleanup EXIT INT TERM

sqlite3 "$database" ".timeout 30000" ".backup '$workdir/state.db'"
install -m 0600 "$server_token" "$workdir/token"

if [ -f /etc/rancher/k3s/config.yaml ]; then
    install -m 0600 /etc/rancher/k3s/config.yaml "$workdir/config.yaml"
fi

sqlite3 "$workdir/state.db" 'PRAGMA integrity_check;' | grep -qx ok
tar -C "$workdir" -czf "$archive" .
sha256sum "$archive" > "$archive.sha256"

# Keep 14 days locally. Off-host retention is managed by the pull host.
find "$backup_root" -maxdepth 1 -type f -name 'k3s-datastore-*.tar.gz*' -mtime +14 -delete

printf '%s\n' "$archive"
