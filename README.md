# What Is This?

These are the scripts that I made to setup an Ubuntu EC2 instance with Wireguard as a VPN to a local machine of mine when I was trapped behind a shared router at an apartment. Hopefully it can help someone else escape this hell faster than I did and get back to hosting their favourite game servers or whatever else you do with this kind of technology. Ideally, you launch an ec2 instance, make the inbound rules match ec2-inbound-rules.png, adjust any configuration variables at the top of the setup scripts, and then you can scp the setup files on to the server and client and just run them and respond to any info that pops out. The server script will attempt to install WireGuard as if the server is Ubuntu, but it is up to you to install WireGuard on the client machine.

```sh
  # Example of a possible way of getting the setup scripts on to the machines.
  scp wireguard-vpn-setup/server-setup.sh user@YOUR_SERVER_PUBLIC_IP:~
  scp wireguard-vpn-setup/client-setup.sh user@YOUR.LOCAL.CLIENT.IP.:~
```

| File                            | Purpose                                                                                                                                                                                                       |
| :------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ec2-inbound-rules.png           | These are the inbound rules on the ec2 instance that line up with these scripts.                                                                                                                              |
| server-setup.sh,client-setup.sh | Functioning (🙏) scripts that can be run on the server/client respectively to make this a bit more streamlined. Scripts are commented and configurable and required variables are at the tops of the scripts. |

# Server Setup

👁️ Server setup available as an executable shell script in server-setup.sh.

# Client Setup

👁️ Client setup available as an executable shell script in client-setup.sh.

### The valheim server needs to be running on a single port.

If you have valheim in Docker, you should only expose the one
port in the DOCKERFILE and only include that one port in the docker
run command. I had some busted behavior because of these things, so leaving this here in case it saves someone in the future. Also, maybe I'm just wrong and something else was broken 🕴️.
