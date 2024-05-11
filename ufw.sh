# This is what 'ufw status' should look like after these commands are run and wg0 is active.
#51820/udp                  ALLOW       Anywhere
#80/tcp                     ALLOW       Anywhere
#443/tcp                    ALLOW       Anywhere
#53/udp                     ALLOW       Anywhere
#22/tcp                     ALLOW       Anywhere
#OpenSSH                    ALLOW       Anywhere
#2459/udp                   ALLOW       Anywhere
#2459/tcp                   ALLOW       Anywhere
#2456/udp                   ALLOW       Anywhere
#2456/tcp                   ALLOW       Anywhere
#51820/udp (v6)             ALLOW       Anywhere (v6)
#80/tcp (v6)                ALLOW       Anywhere (v6)
#443/tcp (v6)               ALLOW       Anywhere (v6)
#53/udp (v6)                ALLOW       Anywhere (v6)
#22/tcp (v6)                ALLOW       Anywhere (v6)
#OpenSSH (v6)               ALLOW       Anywhere (v6)
#2459/udp (v6)              ALLOW       Anywhere (v6)
#2459/tcp (v6)              ALLOW       Anywhere (v6)
#2456/udp (v6)              ALLOW       Anywhere (v6)
#2456/tcp (v6)              ALLOW       Anywhere (v6)
#
#10.20.10.2 2459/udp        ALLOW FWD   Anywhere
#10.20.10.2 2459/tcp        ALLOW FWD   Anywhere
#10.20.10.2 2456/tcp        ALLOW FWD   Anywhere
#10.20.10.2 2456/udp        ALLOW FWD   Anywhere
#Anywhere on enX0           ALLOW FWD   Anywhere on wg0
#Anywhere (v6) on enX0      ALLOW FWD   Anywhere (v6) on wg0

sudo ufw allow 51820/udp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 53/udp
sudo ufw allow 22/tcp
sudo ufw allow OpenSSH
sudo ufw allow 2459/udp
sudo ufw allow 2459/tcp
sudo ufw allow 2456/tcp
sudo ufw allow 2456/tcp
sudo ufw route allow proto udp to 10.20.10.2 port 2459
sudo ufw route allow proto tcp to 10.20.10.2 port 2459
sudo ufw route allow proto udp to 10.20.10.2 port 2456
sudo ufw route allow proto tcp to 10.20.10.2 port 2456
