# Some variables you may want to change
PRIVATE_ADDRESS_OF_SERVER=10.20.10.1
# Example: client_ip1,port,port-client_ip2,port,port-client_ip3-client_ip4,port
# Forwards the port on the server to the same port on the client.
PRIVATE_ADDRESS_AND_PORTS_OF_LOCAL_CLIENTS=10.20.10.2,2456,2459-10.20.10.3
WIREGUARD_PORT=51820
WIREGUARD_CONFIG_FILE=/etc/wireguard/wg0.conf
ALLOWED_CLIENT_IPS=10.20.10.2/32,10.20.10.3/32

# Install Wireguard and Generate Keys
sudo apt update
sudo apt install wireguard
sudo apt install vim
sudo apt install resolvconf

# Server keys
if sudo test ! -e "/etc/wireguard/server-private.key"; then
  wg genkey | sudo tee /etc/wireguard/server-private.key
  sudo chmod go= /etc/wireguard/server-private.key
  sudo cat /etc/wireguard/server-private.key | wg pubkey | sudo tee /etc/wireguard/server-public.key
fi

# Client keys
if sudo test ! -e "/etc/wireguard/client-private.key"; then
  wg genkey | sudo tee /etc/wireguard/client-private.key
  sudo chmod go= /etc/wireguard/client-private.key
  sudo cat /etc/wireguard/client-private.key | wg pubkey | sudo tee /etc/wireguard/client-public.key
fi

# Down WireGuard before changing the rules, because the down will fail later with the new rules.
# Does nothing if WireGuard is not already running.
sudo wg-quick down wg0
sudo systemctl stop wg-quick@wg0.service

# Store the things we need to build the config files
SERVER_PRIVATE_KEY=$(sudo cat /etc/wireguard/server-private.key)
CLIENT_PUBLIC_KEY=$(sudo cat /etc/wireguard/client-public.key)
INTERNET_INTERFACE=$(ip route list default | cut -d " " -f 5)

# Write the server's wireguard config file in $WIREGUARD_CONFIG_FILE
if [ -e "$WIREGUARD_CONFIG_FILE" ]; then
  sudo mv $WIREGUARD_CONFIG_FILE $WIREGUARD_CONFIG_FILE.bak
fi
echo "[Interface]" | sudo tee $WIREGUARD_CONFIG_FILE
echo "Address = $PRIVATE_ADDRESS_OF_SERVER/24" | sudo tee -a $WIREGUARD_CONFIG_FILE
echo "MTU = 1420" | sudo tee -a $WIREGUARD_CONFIG_FILE
echo "# remote server private key" | sudo tee -a $WIREGUARD_CONFIG_FILE
echo "PrivateKey = $SERVER_PRIVATE_KEY" | sudo tee -a $WIREGUARD_CONFIG_FILE
echo "ListenPort = $WIREGUARD_PORT" | sudo tee -a $WIREGUARD_CONFIG_FILE
echo "" | sudo tee -a $WIREGUARD_CONFIG_FILE
echo "PostUp = ufw route allow in on wg0 out on $INTERNET_INTERFACE" | sudo tee -a $WIREGUARD_CONFIG_FILE
echo "PostUp = iptables -t nat -I POSTROUTING -o $INTERNET_INTERFACE -j MASQUERADE" | sudo tee -a $WIREGUARD_CONFIG_FILE

# For each client, forward any ports specified in PRIVATE_ADDRESS_AND_PORTS_OF_LOCAL_CLIENTS.
CLIENTS_WITH_PORTS="$(echo "$PRIVATE_ADDRESS_AND_PORTS_OF_LOCAL_CLIENTS" | cut -d "-" -f 1- --output-delimiter=' ')"
for client_with_ports in $(echo $CLIENTS_WITH_PORTS); do
  CLIENT="$(echo "$client_with_ports" | cut -d "," -f 1)"
  PORTS="$(echo "$client_with_ports" | cut -d "," -f 2- --output-delimiter=',')" # Comma delimiter for dports parameter
  if [ "$PORTS" ] && [ "$CLIENT" ] && [ "$PORTS" != "$CLIENT" ]; then
    echo "PostUp = iptables -t nat -A PREROUTING -i $INTERNET_INTERFACE -p tcp -m multiport --dports $PORTS -j DNAT --to-destination $CLIENT" | sudo tee -a $WIREGUARD_CONFIG_FILE
    echo "PostUp = iptables -t nat -A PREROUTING -i $INTERNET_INTERFACE -p udp -m multiport --dports $PORTS -j DNAT --to-destination $CLIENT" | sudo tee -a $WIREGUARD_CONFIG_FILE
  fi
done

echo "PreDown = ufw route delete allow in on wg0 out on $INTERNET_INTERFACE" | sudo tee -a $WIREGUARD_CONFIG_FILE
echo "PreDown = iptables -t nat -D POSTROUTING -o $INTERNET_INTERFACE -j MASQUERADE" | sudo tee -a $WIREGUARD_CONFIG_FILE
for client_with_ports in $(echo $CLIENTS_WITH_PORTS); do
  CLIENT="$(echo "$client_with_ports" | cut -d "," -f 1 --output-delimiter=' ')"
  PORTS="$(echo "$client_with_ports" | cut -d "," -f 2- --output-delimiter=',')" #Comma delimiter for dports parameter
  if [ "$PORTS" ] && [ "$CLIENT" ] && [ "$PORTS" != "$CLIENT" ]; then
    echo "PreDown = iptables -t nat -D PREROUTING -i $INTERNET_INTERFACE -p tcp -m multiport --dports $PORTS -j DNAT --to-destination $CLIENT" | sudo tee -a $WIREGUARD_CONFIG_FILE
    echo "PreDown = iptables -t nat -D PREROUTING -i $INTERNET_INTERFACE -p udp -m multiport --dports $PORTS -j DNAT --to-destination $CLIENT" | sudo tee -a $WIREGUARD_CONFIG_FILE
  fi
done
echo "" | sudo tee -a $WIREGUARD_CONFIG_FILE
echo "[Peer]" | sudo tee -a $WIREGUARD_CONFIG_FILE
echo "AllowedIPs = $ALLOWED_CLIENT_IPS" | sudo tee -a $WIREGUARD_CONFIG_FILE
echo "# local client public key" | sudo tee -a $WIREGUARD_CONFIG_FILE
echo "PublicKey = $CLIENT_PUBLIC_KEY" | sudo tee -a $WIREGUARD_CONFIG_FILE

# Make a reasonable attempt to enable ipv4 packet forwarding.
sudo sed -E "s/#? ?net.ipv4.ip_forward=[01]?/net.ipv4.ip_forward=1/" -i /etc/sysctl.conf
sudo sysctl -p

# Set up ufw
sudo ufw allow $WIREGUARD_PORT/udp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 53/udp
sudo ufw allow 22/tcp
sudo ufw allow OpenSSH

for client_with_ports in $(echo $CLIENTS_WITH_PORTS); do
  CLIENT="$(echo "$client_with_ports" | cut -d "," -f 1)"
  PORTS="$(echo "$client_with_ports" | cut -d "," -f 2- --output-delimiter=' ')" # Comma delimiter for dports parameter
  if [ "$PORTS" ] && [ "$CLIENT" ] && [ "$PORTS" != "$CLIENT" ]; then
    for port in $(echo $PORTS); do
      sudo ufw allow $port/udp
      sudo ufw allow $port/tcp
      sudo ufw route allow proto udp to "$CLIENT" port "$port"
      sudo ufw route allow proto tcp to "$CLIENT" port "$port"
    done
  fi
done

# If ufw is on, then this disable never seems to happen instanly, so I put a sleep in here. Shoot me.
sudo ufw disable
sleep 1
yes | sudo ufw enable

# Set up wireguard as a service
sudo systemctl enable wg-quick@wg0.service
sudo systemctl start wg-quick@wg0.service
