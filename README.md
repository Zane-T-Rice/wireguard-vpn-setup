# What Is This?
These are the scripts that I made to setup an EC2 instance with Wireguard as a VPN to a local machine of mine when I was trapped behind a shared router at an apartment. Hopefully it can help someone else escape this hell faster than I did and get back to hosting their favourite game servers or whatever else you do with this kind of technology.

| File | Purpose |
| :---- | :------- |
| ec2-inbound-rules.png | These are the inbound rules on the ec2 instance that line up with these scripts.|
| server-wg0.conf, client-wg0.conf | Example wireguard configuration files that line up with these scripts.|
| server-setup.sh,client-setup.sh | Functioning (🙏) scripts that can be run on the server/client respectively to make this a bit more streamlined.|
| ufw.sh | Example ufw setup (also found in the setup scripts).|

# Server Setup

### 👁️ Server setup also available as an executable shell script in server-setup.sh. This guide may help if things don't work after using that script or if you just want to know what is going on.

So to start with you'll need to install wireguard, (vim 🕵️), and resolvconf and
then create private/public keys for the
server.

```sh
sudo apt update
sudo apt install wireguard
sudo apt install vim
sudo apt install resolvconf
wg genkey | sudo tee /etc/wireguard/server-private.key
sudo chmod go= /etc/wireguard/server-private.key
sudo cat /etc/wireguard/server-private.key | wg pubkey | sudo tee /etc/wireguard/public.key
```

Use this to get the default internet interface for the server config routing rules
```sh
ip route list default
```

See server-wg0.conf file for what this config looks like and set yours up to match your specs.
```sh
sudo vim /etc/wireguard/wg0.conf
```

Set net.ipv4.ip_forward=1
```sh
sudo vim /etc/sysctl.conf
sudo sysctl -p
```

Run ufw commands, see ufw.sh for those and update it to match your specs.
Then activate the firewall
```sh
sudo ./ufw.sh
sudo ufw disable
sudo ufw enable
```

Set up wireguard as a service and start it.
```sh
sudo systemctl enable wg-quick@wg0.service
sudo systemctl start wg-quick@wg0.service
```


# Client Setup
### 👁️ Client setup also available as an executable shell script in client-setup.sh. This guide may help if things don't work after using that script or if you just want to know what is going on.
See client-wg0.conf file for what this looks like.
```sh
sudo vim /usr/local/etc/wireguard/wg0.conf
sudo wg-quick up wg0
```

### SSH

If you want to ssh to the local client through the public wireguard vpn you
need to put your public key on the server as well as the client in
authorized_keys and then add the "jump server" (the ec2 instance) to you
~/.ssh/config sorta like this

```
Host SERVER_IP_HERE
IdentityFile /path/to/private_key

Host 10.20.10.2
IdentityFile /path/to/private_key
```

and then you can jump straight to the local client machine from your machine:

```sh
ssh -J user@server.ip user@10.20.10.2 -i /path/to/private_key
```

### 👁️ The valheim server needs to be running on a single port.
If you have valheim in Docker, you should only expose the one
port in the DOCKERFILE and only include that one port in the docker
run command. I had some busted behavior because of these things, so leaving this here in case it saves someone in the future. Also, maybe I'm just wrong and something else was wrong 🕴️.