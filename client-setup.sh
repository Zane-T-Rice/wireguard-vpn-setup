# DISCLAIMER:
# ANY VALUES THAT ARE SET AT THE TOP OF THIS FILE ARE FOR EXAMPLE ONLY.
# YOU SHOULD MAKE SURE THEY ARE SET THE WAY YOU NEED.
#
# You will need to install WireGuard through your client's package manager
# and fill out these variables once you have run the server-setup.sh script.
#
# Note on how I use this: I have several docker containers all within the
# 172.0.0.0/8 space. I use this setup to send all docker traffic over
# WireGuard to effectively give the containers a public IP address.
#
# The public IP of the server where the WireGuard server client script was run.
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
# This is the LAN from which the VPN connection is made from the client side.
# In my case, this is the bridge for a bunch of docker containers,
# but it should work fine for other use cases.
#
# Communication destined for another device in the HOST_LOCAL_IP_ADDRESS
# space will not go over the VPN.
HOST_LOCAL_IP_ADDRESS=172.0.0.0/8
# Communication from all ports on the HOST_LOCAL_IP_ADDRESS will
# go through the VPN unless they are specified here or have a
# destination within the HOST_LOCAL_IP_ADDRESS.
#
# In my case, I like for any normal downloads and such that my containers do
# to go through the normal interface to avoid that data going over the VPN.
AVOID_VPN_FOR_THESE_PORTS=80,443

##
## You should not need to edit below this part unless you know you have
## a special reason to do so.
##

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
if [ "$HOST_LOCAL_IP_ADDRESS" ]; then
  echo "Table = off" >> $WIREGUARD_CONFIG_FILE
  echo "PreUp = sysctl -q net.ipv4.conf.all.src_valid_mark=1" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A PREROUTING -p tcp -s $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 51820" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A PREROUTING -p udp -s $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 51820" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A OUTPUT -p tcp -s $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 51820" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A OUTPUT -p udp -s $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 51820" >> $WIREGUARD_CONFIG_FILE
  if [ "$AVOID_VPN_FOR_THESE_PORTS" ]; then
    echo "PostUp = iptables -t mangle -A PREROUTING -p udp -s $HOST_LOCAL_IP_ADDRESS -m multiport --dports $AVOID_VPN_FOR_THESE_PORTS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
    echo "PostUp = iptables -t mangle -A PREROUTING -p tcp -s $HOST_LOCAL_IP_ADDRESS -m multiport --dports $AVOID_VPN_FOR_THESE_PORTS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
    echo "PostUp = iptables -t mangle -A OUTPUT -p udp -s $HOST_LOCAL_IP_ADDRESS -m multiport --dports $AVOID_VPN_FOR_THESE_PORTS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
    echo "PostUp = iptables -t mangle -A OUTPUT -p tcp -s $HOST_LOCAL_IP_ADDRESS -m multiport --dports $AVOID_VPN_FOR_THESE_PORTS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
  fi
  echo "PostUp = iptables -t mangle -A PREROUTING -p udp -d $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A PREROUTING -p tcp -d $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A OUTPUT -p udp -d $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = iptables -t mangle -A OUTPUT -p tcp -d $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip route add default dev wg0 table 51820" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip rule add from all fwmark 51820 lookup 51820" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip rule add from all fwmark 80 lookup main" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip rule add from all lookup main suppress_prefixlength 0" >> $WIREGUARD_CONFIG_FILE
  echo "PostUp = ip route flush cached" >> $WIREGUARD_CONFIG_FILE
  echo "" >> $WIREGUARD_CONFIG_FILE
fi
if [ "$HOST_LOCAL_IP_ADDRESS" ]; then
  echo "PreDown = iptables -t mangle -D PREROUTING -p tcp -s $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 51820" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D PREROUTING -p udp -s $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 51820" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D OUTPUT -p tcp -s $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 51820" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D OUTPUT -p udp -s $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 51820" >> $WIREGUARD_CONFIG_FILE
  if [ "$AVOID_VPN_FOR_THESE_PORTS" ]; then
    echo "PreDown = iptables -t mangle -D PREROUTING -p udp -s $HOST_LOCAL_IP_ADDRESS -m multiport --dports $AVOID_VPN_FOR_THESE_PORTS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
    echo "PreDown = iptables -t mangle -D PREROUTING -p tcp -s $HOST_LOCAL_IP_ADDRESS -m multiport --dports $AVOID_VPN_FOR_THESE_PORTS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
    echo "PreDown = iptables -t mangle -D OUTPUT -p udp -s $HOST_LOCAL_IP_ADDRESS -m multiport --dports $AVOID_VPN_FOR_THESE_PORTS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
    echo "PreDown = iptables -t mangle -D OUTPUT -p tcp -s $HOST_LOCAL_IP_ADDRESS -m multiport --dports $AVOID_VPN_FOR_THESE_PORTS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
  fi
  echo "PreDown = iptables -t mangle -D PREROUTING -p udp -d $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D PREROUTING -p tcp -d $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D OUTPUT -p udp -d $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = iptables -t mangle -D OUTPUT -p tcp -d $HOST_LOCAL_IP_ADDRESS -j MARK --set-mark 80" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = ip rule delete from all fwmark 51820 lookup 51820" >> $WIREGUARD_CONFIG_FILE
  echo "PreDown = ip rule delete from all fwmark 80 lookup main" >> $WIREGUARD_CONFIG_FILE
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
