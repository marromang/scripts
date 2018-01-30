#!/bin/bash
#ejecucion de la practica 8 de SAD
#nftables de 2 patas

echo "Preparando el entorno"
modprobe nf_tables 
modprobe nf_tables_ipv4
modprobe  nf_tables_bridge
modprobe  nf_tables_inet
modprobe  nf_tables_arp
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "Comprueba que el defult de los clientes sale por 192.168.1.10"

echo "Politica por defacto DROP"
systemctl start nftables
#acceso ssh 
nft add rule inet filter input tcp dport 22 accept
nft add rule inet filter output tcp sport 22 accept
nft add rule inet filter forward tcp sport 22 accept
#Politica drop
nft add chain inet filter input { type filter hook input priority 0 \; policy drop \;}
nft add chain inet filter output { type filter hook output priority 0 \;  policy drop \;}
nft add chain inet filter forward { type filter hook forward priority 0 \;  policy drop \;}

echo "Acceso a internet"
#creacion de la tabla
nft add table nat
#acceso a internet
nft add chain nat prerouting { type nat hook prerouting priority 1 \; }
nft add chain nat postrouting { type nat hook postrouting priority 100 \; }
nft add rule nat postrouting ip saddr 192.168.1.0/24 oif eth0 nftrace set 1 masquerade

echo "Bloqueo de as y marca"
#as
nft add rule nat prerouting ip saddr 192.168.10.0/24 ip daddr 91.216.63.240 drop
#marca
nft add rule nat prerouting ip saddr 192.168.1.0/24 ip daddr 91.216.63.241 drop
nft add rule nat prerouting ip saddr 192.168.1.0/24 ip daddr 193.110.128.109 drop

echo "Loopback"
nft add rule inet filter input iif lo accept
nft add rule inet filter output oif lo accept
nft add rule inet filter forward oif lo accept

echo "El router podrá realizar conexiones ssh"
nft add rule inet filter input tcp sport 22 accept
nft add rule inet filter output tcp dport 22 accept
nft add rule inet filter forward tcp dport 22 accept

echo "El router ofrece un servicio ssh accesible desde el exterior"
#Estan añadidas en la parte de la politica DROP
#nft add rule inet filter input tcp dport 22 accept
#nft add rule inet filter output tcp sport 22 accept
#nft add rule inet filter forward tcp sport 22 accept

echo "El router podrá ser cliente DNS"
nft add rule inet filter input udp sport 53 accept
nft add rule inet filter output udp dport 53 accept
nft add rule inet filter forward udp dport 53 accept
nft add rule inet filter input tcp sport 53 accept
nft add rule inet filter output tcp dport 53 accept
nft add rule inet filter forward tcp dport 53 accept

echo "El router podrá ser cliente HTTP"
nft add rule inet filter output tcp dport 80 accept
nft add rule inet filter input tcp sport 80 accept
nft add rule inet filter forward tcp dport 80 accept

echo "El router podrá ser cliente HTTPS"
nft add rule inet filter output tcp sport 443 accept
nft add rule inet filter forward tcp sport 443 accept  

echo "PC1 ofrece un servidor web accesible por http desde fuera"
nft add rule nat prerouting iif eth1 tcp dport 80 dnat 192.168.1.2
nft add rule inet filter forward oif eth1 tcp sport 80 accept

echo "PC2 ofrece un servidor FTP accesible desde el exterior"
nft add rule nat prerouting iif eth0 tcp dport 21 dnat 192.168.1.3
nft add rule inet filter forward oif eth0 tcp sport 21 accept
nft add rule inet filter forward iif eth0 tcp dport 21 accept

echo "PC1 puede hacer ping"
nft add rule inet filter input ip protocol icmp accept
nft add rule inet filter output ip protocol icmp accept
nft add rule inet filter forward ip protocol icmp accept
nft add rule inet filter output ip daddr 192.168.1.2 accept
nft add rule inet filter input ip daddr 192.168.1.2 accept
nft add rule inet filter forward ip daddr 192.168.1.2 accept

echo "Seguridad adicional"
echo "Bloqueo de escaneo de puertos"
nft add rule inet filter input tcp flags "& (syn|ack) == syn|ack" ct state new drop
nft add rule inet filter input tcp flags "& (fin|syn|rst|psh|ack|urg) == 0x0" drop
nft add rule inet filter input tcp flags "& (fin|syn) == fin|syn" drop
nft add rule inet filter input tcp flags "& (syn|rst) == syn|rst" drop
nft add rule inet filter input tcp flags "& (fin|syn|rst|psh|ack|urg) == fin|syn|rst|ack|urg" drop
nft add rule inet filter input tcp flags "& (fin|rst) == fin|rst" drop
nft add rule inet filter input tcp flags "& (fin|ack) == fin" drop
nft add rule inet filter input tcp flags "& (psh|ack) == psh" drop
nft add rule inet filter input tcp flags "& (ack|urg) == urg" counter drop
echo "Protección contras ataques DoS SYN Flood"
#nft add table inet filter
nft add chain inet filter syn-flood
nft add rule inet filter syn-flood limit rate 10/second burst 50 packets return
nft add rule inet filter syn-flood drop

echo "Protección contras ataques DoS PIng Flooding"
nft add rule inet filter forward ip frag-off != 0 ip protocol icmp drop
