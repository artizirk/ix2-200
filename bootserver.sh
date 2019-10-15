#!/bin/bash
if [[ "$(id -u)" -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

SOURCE_RAUCB=
NETDEV=
if [[ -n "$1" && -n "$2" ]]; then
    if ip link show "$1" >/dev/null 2>&1; then
        NETDEV="$1"
    else
        echo "Network device '$1' seems to be non-existent"
        exit 1
    fi
    if [[ -f "$2" ]]; then
        if [[ "$2" == *.raucb ]]; then
            SOURCE_RAUCB="$(realpath "$2")"
            SERVER_DIR="$(mktemp --directory /tmp/rauc-os-bootserver-XXXXXX)"
            mount "$SOURCE_RAUCB" "$SERVER_DIR"
            echo "Files will be served from '${SERVER_DIR}' which is mounted from '${SOURCE_RAUCB}'"
        else
            echo "Provided file must end with .raucb"
            exit 1
        fi
    elif [[ -d "$2" ]]; then
        SERVER_DIR="$(realpath "$2")"
        echo "Files will be served from '${SERVER_DIR}'"
    else
        echo "The provided file/directory '$2' does not exist"
        exit 1
    fi
else
    echo "Usage: $0 <net dev> <server dir/raucb file>"
    echo
    echo "Starts dnsmasq with tftp for netboot and a http webserver for serving files"
    exit 1
fi

SERVER_IP="10.0.0.1/24"

ADDED_IP="false"
if ip address add "$SERVER_IP" dev "$NETDEV" >/dev/null 2>&1; then
    echo "Added IP '$SERVER_IP' to network device '$NETDEV'"
    ADDED_IP="true"
fi
if ! ip link set "$NETDEV" up; then
    echo "Failed to set link '$NETDEV' up."
    exit 1
fi

dnsmasq --no-daemon \
    --tftp-root="$SERVER_DIR" \
    --port=0 \
    --dhcp-range=10.0.0.10,10.0.0.200,255.255.255.0 \
    --enable-tftp \
    --dhcp-option=3 \
    --dhcp-option=6 \
    --bind-dynamic \
    --dhcp-boot=boot.scr.uimg &
DNSMASQ_PID="$!"
echo "DNSMASQ_PID $DNSMASQ_PID"

( cd "$SERVER_DIR"; python3 -m http.server 80 )&
HTTP_PID="$!"
echo "HTTP_PID $HTTP_PID"

trap kill_servers INT
function kill_servers() {
    echo "Killing servers"
    kill -15 "$DNSMASQ_PID"
    kill -15 "$HTTP_PID"

    if [[ "$ADDED_IP" == "true" ]]; then
        ip address del "$SERVER_IP" dev "$NETDEV" && \
            echo "Deleted IP '$SERVER_IP' from network device '$NETDEV'"
    fi

    if [[ -n "$SOURCE_RAUCB" ]]; then
        sleep 1
        umount "$SERVER_DIR" && rm -r "$SERVER_DIR"
    fi
}

wait "$DNSMASQ_PID" "$HTTP_PID"
echo "Servers have exited"
