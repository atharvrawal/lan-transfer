#!/bin/bash

set -e

echo "Uninstalling lan-transfer..."

# --- check bash ---
if [[ "$SHELL" != *"bash" ]]; then
    echo "❌ Unsupported shell: $SHELL"
    echo "This installer modifies ~/.bashrc and assumes bash."
    exit 1
fi

BASHRC="$HOME/.bashrc"

# --- check if installed ---
if ! grep -q ">>> lan-transfer >>>" "$BASHRC"; then
    echo "lan-transfer not found in .bashrc"
    exit 0
fi

# --- remove block ---
sed -i '/# >>> lan-transfer >>>/,/# <<< lan-transfer <<</d' "$BASHRC"

echo "✅ Removed lan-transfer from .bashrc"
echo "Run: source ~/.bashrc"