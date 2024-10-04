# You will need to install WireGuard through your client's package manager
# and fill out these variables once you have run the server-setup.sh script.
PUBLIC_ADDRESS_OF_SERVER=
# The server-setup script generated this in /etc/wireguard/server-public.key
SERVER_PUBLIC_KEY=
# The server-setup script generated this in /etc/wireguard/client-private.key
CLIENT_PRIVATE_KEY=
# This directory must exist, the wg0.conf file will be created however.
WIREGUARD_CONFIG_FILE=$HOME/.config/wireguard/wg0.conf
PRIVATE_ADDRESS_OF_LOCAL_CLIENT=10.20.10.2
WIREGUARD_PORT=51820
# This will make the connection a vpn.
ALLOWED_IPs=0.0.0.0/0
# Comma seperated list of source ports that should be sent over the wireguard vpn.
# This uses the iptables sytax, so ports can be specified like 0:1000,1002,1003:1010.
USE_VPN_INTERFACE_FOR_PORTS=

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
echo "## Local Address : A private IP address for wg0 interface." >> $WIREGUARD_CONFIG_FILE
echo "Address = $PRIVATE_ADDRESS_OF_LOCAL_CLIENT/24" >> $WIREGUARD_CONFIG_FILE
echo "ListenPort = $WIREGUARD_PORT" >> $WIREGUARD_CONFIG_FILE
echo "" >> $WIREGUARD_CONFIG_FILE
if [ "$USE_VPN_INTERFACE_FOR_PORTS" ]; then
  echo "Table = off" >> $WIREGUARD_CONFIG_FILE
  echo "PreUp = sysctl -q net.ipv4.conf.all.src_valid_mark=1" >> $WIREGUARD_CONFIG_FILE
  echo "" >> $WIREGUARD_CONFIG_FILE
  echo "# Mark the specific traffic that should go through the vpn based on the source port" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A OUTPUT -p tcp -m multiport --sports $USE_VPN_INTERFACE_FOR_PORTS -j MARK --set-mark 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A OUTPUT -p udp -m multiport --sports $USE_VPN_INTERFACE_FOR_PORTS -j MARK --set-mark 4242" >> $WIREGUARD_CONFIG_FILE
  echo "# Mark 192.168.1.* traffic to go through local network" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A OUTPUT -p tcp -d 192.168.1.0/24 -j MARK --set-mark 4243" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A OUTPUT -p udp -d 192.168.1.0/24 -j MARK --set-mark 4243" >> $WIREGUARD_CONFIG_FILE
  echo "# Add rules to send marks the correct way" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip route add 0.0.0.0/0 dev wg0 table 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip rule add from all fwmark 4242 lookup 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip route add 0.0.0.0/0 dev eno1 table 4243" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip rule add from all fwmark 4243 lookup 4243" >> $WIREGUARD_CONFIG_FILE
  echo "" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D OUTPUT -p tcp -m multiport --sports $USE_VPN_INTERFACE_FOR_PORTS -j MARK --set-mark 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D OUTPUT -p udp -m multiport --sports $USE_VPN_INTERFACE_FOR_PORTS -j MARK --set-mark 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D OUTPUT -p tcp -d 192.168.1.0/24 -j MARK --set-mark 4243" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D OUTPUT -p udp -d 192.168.1.0/24 -j MARK --set-mark 4243" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = ip route delete 0.0.0.0/0 dev wg0 table 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = ip rule delete from all fwmark 4242 lookup 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = ip route delete 0.0.0.0/0 dev eno1 table 4243" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = ip rule delete from all fwmark 4243 lookup 4243" >> $WIREGUARD_CONFIG_FILE
  echo "" >> $WIREGUARD_CONFIG_FILE
fi
echo "## local client privatekey" >> $WIREGUARD_CONFIG_FILE
echo "PrivateKey = $CLIENT_PRIVATE_KEY" >> $WIREGUARD_CONFIG_FILE
echo "" >> $WIREGUARD_CONFIG_FILE
echo "[Peer]" >> $WIREGUARD_CONFIG_FILE
echo "# remote server public key" >> $WIREGUARD_CONFIG_FILE
echo "PublicKey = $SERVER_PUBLIC_KEY" >> $WIREGUARD_CONFIG_FILE
echo "Endpoint = $PUBLIC_ADDRESS_OF_SERVER:$WIREGUARD_PORT" >> $WIREGUARD_CONFIG_FILE
echo "AllowedIPs = $ALLOWED_IPs" >> $WIREGUARD_CONFIG_FILE

sudo wg-quick down $WIREGUARD_CONFIG_FILE
sudo wg-quick up $WIREGUARD_CONFIG_FILE
