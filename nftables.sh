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
#creacion de la tabla
nft add table inet filter
#acceso ssh 


#Politica drop
nft add chain inet filter input { type filter hook input priority 0 \; policy drop \;}
nft add chain inet filter output { type filter hook output priority 0 \;  policy drop \;}
nft add chain inet filter forward { type filter hook forward priority 0 \;  policy drop \;}

echo "Acceso a internet"
#creacion de la tabla
nft add table nat
#acceso a internet
nft add chain nat prerouting { type nat hook prerouting priority 1 \; }
nft add chain nat postrouting { type nat hook postrouting priority 1 \; }
nft add rule nat postrouting ip saddr 192.168.1.0/24 oif eth0 nftrace set 1 masquerade

echo "Bloqueo de as y marca"
#as
nft add rule nat prerouting ip saddr 192.168.1.0/24 ip daddr 91.216.63.241 drop
nft add rule nat prerouting ip saddr 192.168.1.0/24 ip daddr 193.110.128.109 drop
#marca
nft add rule nat prerouting ip saddr 192.168.1.0/24 ip daddr 91.216.63.241 drop
nft add rule nat prerouting ip saddr 192.168.1.0/24 ip daddr 193.110.128.109 drop


echo "Loopback"
nft add rule inet filter input iif lo protocol icmp accept
nft add rule inet filter output oif lo accept
nft add rule inet filter forward oif lo accept

echo "El router podrá realizar conexiones ssh"
echo "El router ofrece un servicio ssh accesible desde el exterior"
echo "El router podrá ser cliente DNS"
echo "El router podrá ser cliente HTTP"
echo "El router podrá ser cliente HTTPS"
echo "PC1 ofrece un servidor web accesible por http desde fuera"
echo "PC2 ofrece un servidor FTP accesible desde el exterior"
echo "PC1 puede hacer ping"



echo "Seguridad adicional"
echo "Bloqueo de escaneo de puertos"
nft add rule ip filter input tcp flags "& (syn|ack) == syn|ack" ct state new drop
nft add rule ip filter input tcp flags "& (fin|syn|rst|psh|ack|urg) == 0x0" drop
nft add rule ip filter input tcp flags "& (fin|syn) == fin|syn" drop
nft add rule ip filter input tcp flags "& (syn|rst) == syn|rst" drop
nft add rule ip filter input tcp flags "& (fin|syn|rst|psh|ack|urg) == fin|syn|rst|ack|urg" drop
nft add rule ip filter input tcp flags "& (fin|rst) == fin|rst" drop
nft add rule ip filter input tcp flags "& (fin|ack) == fin" drop
nft add rule ip filter input tcp flags "& (psh|ack) == psh" drop
nft add rule ip filter input tcp flags "& (ack|urg) == urg" counter drop

echo "Protección contras ataques DoS SYN Flood"
#nft add table ip filter
nft add chain ip filter syn-flood
nft add rule ip filter syn-flood limit rate 10/second burst 50 packets return
nft add rule ip filter syn-flood drop


echo "Protección contras ataques DoS PIng Flooding"
nft add rule ip filter forward ip frag-off != 0 ip protocol icmp drop

