#!/bin/bash
droidpush() {
    # --- usage check ---
    if [ $# -eq 0 ]; then
        echo "Usage: droidpush <file_or_folder>"
        return 1
    fi

    SRC="$1"
    DEST="/storage/emulated/0/Download"
    PORT=42069
    USER="u0_a235"

    # --- get base subnet ---
    BASE_IP=$(ip route | awk '/default/ {print $3}' | sed 's/\.[0-9]*$//')

    # --- find phone IP ---
    PHONE_IP=$(for i in $(seq 1 254); do
        echo "$BASE_IP.$i"
    done | xargs -P 50 -I {} sh -c "nc -z -w 1 {} $PORT 2>/dev/null && echo {}" | head -n1)

    # --- validate ---
    if [ -z "$PHONE_IP" ]; then
        echo "Phone not found on LAN"
        return 1
    fi

    echo "Using IP: $PHONE_IP"
    echo "Sending: $SRC → $DEST"

    # --- transfer ---
    rsync -avL --info=progress2 --whole-file \
        -e "ssh -p $PORT" \
        "$SRC" "$USER@$PHONE_IP:$DEST"
}

droidpush "$@"
