#!/usr/bin/env bash
set -euo pipefail
umask 077
out="${1:-$HOME/bridge-pairing}"
mkdir "$out"
cd "$out"
read -r -s -p "Pairing password (at least 12 characters): " PAIR_PASSWORD
printf '\n'
[[ ${#PAIR_PASSWORD} -ge 12 ]] || { echo "Password too short"; exit 1; }
export PAIR_PASSWORD
trap 'unset PAIR_PASSWORD' EXIT
for role in server client; do
  eku=serverAuth
  [[ "$role" == client ]] && eku=clientAuth
  openssl req -new -x509 -newkey rsa:2048 -nodes -sha256 -days 365 \
    -subj "/CN=LocalBridge-$role" \
    -addext "basicConstraints=critical,CA:FALSE" \
    -addext "keyUsage=critical,digitalSignature,keyEncipherment" \
    -addext "extendedKeyUsage=$eku" \
    -keyout "$role.key" -out "$role.pem"
  openssl pkcs12 -export -inkey "$role.key" -in "$role.pem" \
    -name "$role" -out "$role.p12" -passout env:PAIR_PASSWORD
  rm "$role.key"
done
openssl x509 -in server.pem -noout -fingerprint -sha256 | cut -d= -f2 | tr -d ':' > server-fingerprint.txt
echo "Android: server.p12 and client.pem"
echo "iOS: client.p12 and server-fingerprint.txt"
echo "Keep private identities local. Never commit or upload PKCS12 files."
