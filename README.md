# What Is This?

These are the scripts that I made to setup an Ubuntu EC2 instance with Wireguard as a VPN to a local machine of mine when I was trapped behind a shared router at an apartment. Hopefully it can help someone else escape this hell faster than I did and get back to hosting their favourite game servers or whatever else you do with this kind of technology. Ideally, you launch an ec2 instance, update the inbound rules to allow any ports you need to expose, adjust any configuration variables at the top of the setup scripts, and then you can scp the setup files on to the server and client and just run them. The server script will attempt to install WireGuard as if the server is Ubuntu, but it is up to you to install WireGuard on the client machine.

| File                            | Purpose                                                                                                                                                                                                       |
| :------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| server-setup.sh,client-setup.sh | Functioning (🙏) scripts that can be run on the server/client respectively to make this a bit more streamlined. Scripts are commented and configurable and required variables are at the tops of the scripts. |

# Server Setup

👁️ Server setup available as an executable shell script in server-setup.sh.

# Client Setup

👁️ Client setup available as an executable shell script in client-setup.sh.

### Some Useful Commands

```sh
  # This command will show you the policy chain that is applied to packets. Very useful for making sure packet marks are being applied as you think.
  iptables -t mangle -L

  # These commands help you see what ip tables exist and what routes each table uses.
  ip -r rule list
  ip route show table table_name
```
