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
# Comma seperated list of ports that should be sent over the wireguard vpn.
# This uses the iptables sytax, so ports can be specified like 0:1000,1002,1003:1010.
USE_VPN_INTERFACE_FOR_PORTS=

# Write the client's wireguard config file in $WIREGUARD_CONFIG_FILE
if [ ! "$PUBLIC_ADDRESS_OF_SERVER" ] || [ ! "$SERVER_PUBLIC_KEY" ] || [ ! "$CLIENT_PRIVATE_KEY" ]; then
  echo "Please fill in the public IP of your server, public key of the server, and private key of the client."
  exit
fi;

if [ -e "$WIREGUARD_CONFIG_FILE" ]; then
  sudo wg-quick down $WIREGUARD_CONFIG_FILE
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
  echo "fwmark = 51820" >> $WIREGUARD_CONFIG_FILE
  echo "" >> $WIREGUARD_CONFIG_FILE
  echo "# Flow is:" >> $WIREGUARD_CONFIG_FILE
  echo "# 32761:  from all lookup main suppress_prefixlength 0" >> $WIREGUARD_CONFIG_FILE
  echo "# 32762:  from all fwmark 0xca6c lookup main" >> $WIREGUARD_CONFIG_FILE
  echo "# 32763:  from all fwmark 0x1092 lookup 51820" >> $WIREGUARD_CONFIG_FILE
  echo "# 32766:  from all lookup main" >> $WIREGUARD_CONFIG_FILE
  echo "# 32767:  from all lookup default" >> $WIREGUARD_CONFIG_FILE
  echo "#" >> $WIREGUARD_CONFIG_FILE
  echo "# 32761: (Local 192.168.1.0/24) If it is handled by main default -> main" >> $WIREGUARD_CONFIG_FILE
  echo "# 32762: (Infinite packet loop prevention) If it originated in the VPN -> main" >> $WIREGUARD_CONFIG_FILE
  echo "# 32763: If it matches a source port that we want to use the VPN for -> VPN (mark 4242, 51820 table)" >> $WIREGUARD_CONFIG_FILE
  echo "# 32766: Standard main table" >> $WIREGUARD_CONFIG_FILE
  echo "# 32767: Standard default table" >> $WIREGUARD_CONFIG_FILE
  echo "" >> $WIREGUARD_CONFIG_FILE
  echo "##### Mark the source ports that should go through the VPN." >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A PREROUTING  -p udp -j CONNMARK --restore-mark" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A POSTROUTING -p udp -m mark --mark 51820 -j CONNMARK --save-mark" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A PREROUTING -p tcp -m multiport --dports $USE_VPN_INTERFACE_FOR_PORTS -j MARK --set-mark 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A PREROUTING -p udp -m multiport --dports $USE_VPN_INTERFACE_FOR_PORTS -j MARK --set-mark 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A OUTPUT -p tcp -m multiport --dports $USE_VPN_INTERFACE_FOR_PORTS -j MARK --set-mark 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A OUTPUT -p udp -m multiport --dports $USE_VPN_INTERFACE_FOR_PORTS -j MARK --set-mark 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip route add default dev wg0 table 51820" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip rule add from all fwmark 4242 lookup 51820" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip rule add from all fwmark 51820 lookup main" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip rule add from all lookup main suppress_prefixlength 0" >> $WIREGUARD_CONFIG_FILE
  echo "" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D PREROUTING  -p udp -j CONNMARK --restore-mark" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D POSTROUTING -p udp -m mark --mark 51820 -j CONNMARK --save-mark" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D PREROUTING -p tcp -m multiport --dports $USE_VPN_INTERFACE_FOR_PORTS -j MARK --set-mark 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D PREROUTING -p udp -m multiport --dports $USE_VPN_INTERFACE_FOR_PORTS -j MARK --set-mark 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D OUTPUT -p tcp -m multiport --dports $USE_VPN_INTERFACE_FOR_PORTS -j MARK --set-mark 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D OUTPUT -p udp -m multiport --dports $USE_VPN_INTERFACE_FOR_PORTS -j MARK --set-mark 4242" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = ip rule delete from all fwmark 4242 lookup 51820" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = ip rule delete from all fwmark 51820 lookup main" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = ip rule delete from all lookup main suppress_prefixlength 0" >> $WIREGUARD_CONFIG_FILE
fi
echo "## local client privatekey" >> $WIREGUARD_CONFIG_FILE
echo "PrivateKey = $CLIENT_PRIVATE_KEY" >> $WIREGUARD_CONFIG_FILE
echo "" >> $WIREGUARD_CONFIG_FILE
echo "[Peer]" >> $WIREGUARD_CONFIG_FILE
echo "# remote server public key" >> $WIREGUARD_CONFIG_FILE
echo "PublicKey = $SERVER_PUBLIC_KEY" >> $WIREGUARD_CONFIG_FILE
echo "Endpoint = $PUBLIC_ADDRESS_OF_SERVER:$WIREGUARD_PORT" >> $WIREGUARD_CONFIG_FILE
echo "AllowedIPs = $ALLOWED_IPs" >> $WIREGUARD_CONFIG_FILE
echo "PersistentKeepalive = 25" >> $WIREGUARD_CONFIG_FILE

sudo wg-quick up $WIREGUARD_CONFIG_FILE
