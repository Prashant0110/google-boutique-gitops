#!/usr/bin/env bash
set -e

read -rsp "Unseal Key 1: " K1; echo
read -rsp "Unseal Key 2: " K2; echo
read -rsp "Unseal Key 3: " K3; echo

KEY1=$(echo "$K1" | tr -d '[:space:]')
KEY2=$(echo "$K2" | tr -d '[:space:]')
KEY3=$(echo "$K3" | tr -d '[:space:]')

CA="/vault/userconfig/vault-tls/tls.crt"

for pod in vault-0 vault-1 vault-2; do
  echo "==> Unsealing $pod..."
  for k in "$KEY1" "$KEY2" "$KEY3"; do
    kubectl exec -n vault "$pod" -- sh -c \
      "export VAULT_ADDR=https://127.0.0.1:8200; export VAULT_CACERT=$CA; vault operator unseal '$k'" >/dev/null
  done
done

echo "==> All Vault nodes processed."
