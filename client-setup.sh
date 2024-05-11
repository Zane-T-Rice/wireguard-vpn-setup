# Some configuration that you need to fill out.
PUBLIC_ADDRESS_OF_SERVER=
# The server-setup script generated this in /etc/wireguard/server-public.key
SERVER_PUBLIC_KEY=
# The server-setup script generated this in /etc/wireguard/client-private.key
CLIENT_PRIVATE_KEY=

# Some more configuration that you might want to change.
WIREGUARD_CONFIG_FILE=/usr/local/etc/wireguard/wg0.conf
PRIVATE_ADDRESS_OF_LOCAL_CLIENT=10.20.10.2
WIREGUARD_PORT=51820

# This will make the connection a vpn.
ALLOWED_IPs=0.0.0.0/0

# Write the client's wireguard config file in $WIREGUARD_CONFIG_FILE
if [ ! "$PUBLIC_ADDRESS_OF_SERVER" ] || [ ! "$SERVER_PUBLIC_KEY" ] || [ ! "$CLIENT_PRIVATE_KEY" ]; then
  echo "Please fill in the public IP of your server, public key of the server, and private key of the client."
  exit
fi;

if [ -e "$WIREGUARD_CONFIG_FILE" ]; then
  mv $WIREGUARD_CONFIG_FILE $WIREGUARD_CONFIG_FILE.bak
fi
touch $WIREGUARD_CONFIG_FILE 
echo "[Interface]" > $WIREGUARD_CONFIG_FILE
echo "## Local Address : A private IP address for wg0 interface."
echo "Address = $PRIVATE_ADDRESS_OF_LOCAL_CLIENT/24"
echo "ListenPort = $WIREGUARD_PORT"
echo ""
echo "## local client privateky"
echo "PrivateKey = $CLIENT_PRIVATE_KEY"
echo ""
echo "[Peer]"
echo "# remote server public key"
echo "PublicKey = $SERVER_PUBLIC_KEY"
echo "Endpoint = $PUBLIC_ADDRESS_OF_SERVER:$WIREGUARD_PORT"
echo "AllowedIPs = $ALLOWED_IPs"

sudo wg-quick up wg0