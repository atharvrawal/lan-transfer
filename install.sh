#!/bin/bash

set -e

echo "Installing lan-transfer..."

# --- check shell ---
if [[ "$SHELL" != *"bash" ]]; then
    echo "❌ Unsupported shell: $SHELL"
    echo "This installer modifies ~/.bashrc and assumes bash."
    echo "If you want to proceed anyway, run manually."
    exit 1
fi

BASHRC="$HOME/.bashrc"

# --- avoid duplicate install ---
if grep -q "lan-transfer" "$BASHRC"; then
    echo "Already installed (found marker in .bashrc)"
    exit 0
fi

echo "Adding functions to $BASHRC..."

# --- append functions ---
cat >> "$BASHRC" << 'EOF'

# >>> lan-transfer >>>
droidpush() {
    if [ $# -eq 0 ]; then
        echo "Usage: droidpush <file_or_folder>"
        return 1
    fi

    SRC="$1"
    DEST="/storage/emulated/0/Download"
    PORT=42069
    USER="u0_a235"

    BASE_IP=$(ip route | awk '/default/ {print $3}' | sed 's/\.[0-9]*$//')

    PHONE_IP=$(for i in $(seq 1 254); do
        echo "$BASE_IP.$i"
    done | xargs -P 50 -I {} sh -c "nc -z -w 1 {} $PORT 2>/dev/null && echo {}" | head -n1)

    if [ -z "$PHONE_IP" ]; then
        echo "Phone not found on LAN"
        return 1
    fi

    echo "Using IP: $PHONE_IP"
    echo "Sending: $SRC → $DEST"

    rsync -avL --info=progress2 --whole-file \
        -e "ssh -p $PORT" \
        "$SRC" "$USER@$PHONE_IP:$DEST"
}

droidpull() {
    for cmd in ssh rsync fzf nc ip; do
        command -v "$cmd" >/dev/null || {
            echo "$cmd is required but not installed"
            return 1
        }
    done

    BASE="/storage/emulated/0"
    PORT="${PHONE_PORT:-42069}"
    SSH_OPTS="-p $PORT -o ConnectTimeout=1 -o BatchMode=yes"

    GATEWAY=$(ip route | awk '/default/ {print $3}')
    SUBNET=$(echo "$GATEWAY" | sed 's/\.[0-9]*$//')

    is_phone() {
        local ip="$1"
        OUTPUT=$(ssh $SSH_OPTS "$ip" 'whoami && uname' 2>/dev/null) || return 1
        USERNAME=$(echo "$OUTPUT" | head -n1)
        OS=$(echo "$OUTPUT" | tail -n1)

        if [[ "$USERNAME" == u0_a* ]] && [[ "$OS" == *Linux* ]]; then
            echo "$USERNAME"
            return 0
        fi

        return 1
    }

    PHONE_IP=""
    PHONE_USER=""

    while read -r ip; do
        RESULT=$(is_phone "$ip") || continue
        PHONE_IP="$ip"
        PHONE_USER="$RESULT"
        break
    done < <(
        for i in $(seq 1 254); do
            echo "$SUBNET.$i"
        done | xargs -P 50 -I {} sh -c "nc -z -w 1 {} $PORT 2>/dev/null && echo {}"
    )

    if [ -z "$PHONE_IP" ] || [ -z "$PHONE_USER" ]; then
        echo "Phone not found on LAN"
        return 1
    fi

    echo "Connected to phone: $PHONE_USER@$PHONE_IP"

    CUR="$BASE"

    while true; do
        mapfile -t CHOICE < <(
            ssh $SSH_OPTS "$PHONE_USER@$PHONE_IP" \
            "cd \"$CUR\" && echo '..'; ls -1p" \
            | fzf --prompt="$CUR > " --expect=ctrl-d
        )

        KEY="${CHOICE[0]}"
        ITEM="${CHOICE[1]}"

        if [ -z "$ITEM" ]; then
            echo "Cancelled"
            return 1
        fi

        if [ "$ITEM" = ".." ]; then
            CUR=$(dirname "$CUR")
            continue
        fi

        if [ "$KEY" = "ctrl-d" ]; then
            TARGET="$CUR/$ITEM"
            break
        fi

        if [[ "$ITEM" == */ ]]; then
            CUR="$CUR/$(echo "$ITEM" | sed 's:/*$::')"
        else
            TARGET="$CUR/$ITEM"
            break
        fi
    done

    rsync -avL --info=progress2 --whole-file \
        -e "ssh $SSH_OPTS" \
        "$PHONE_USER@$PHONE_IP":"$TARGET" .
}
# <<< lan-transfer <<<

EOF

echo "✅ Installed successfully."
echo "Run: source ~/.bashrc"