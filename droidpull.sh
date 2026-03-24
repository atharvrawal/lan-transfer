#!/bin/bash
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

    # detect subnet
    GATEWAY=$(ip route | awk '/default/ {print $3}')
    SUBNET=$(echo "$GATEWAY" | sed 's/\.[0-9]*$//')

    # verify candidate + extract user
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

    # scan + verify
    while read -r ip; do
        RESULT=$(is_phone "$ip") || continue

        PHONE_IP="$ip"
        PHONE_USER="$RESULT"
        break
    done < <(
        for i in $(seq 1 254); do
            echo "$SUBNET.$i"
        done | xargs -P 50 -I {} sh -c "
            nc -z -w 1 {} $PORT 2>/dev/null && echo {}
        "
    )

    # validate
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


droidpull
