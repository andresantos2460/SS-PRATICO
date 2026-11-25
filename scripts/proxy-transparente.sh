#!/bin/bash
# =====================================================================
#  proxy-transparente.sh  -  GATEWAY com Squid em modo transparente
#  HTTP (80) vindo da LAN é desviado para o Squid (porto 3129 intercept).
#  No /etc/squid/squid.conf tem de existir:
#      http_port 3128
#      http_port 3129 intercept
#  Usar:  sudo ./proxy-transparente.sh
# =====================================================================
IPT=/sbin/iptables
DYN=1024:65535

# ---- AJUSTAR (ip -br a) --------------------------------------------
WAN=enp0s3
LAN=enp0s8
REDE_LAN=192.168.56.0/24
SQUID=3129

echo "Ativar o encaminhamento de pacotes"
sysctl -w net.ipv4.ip_forward=1

# ----- inicialização (filter + nat)
$IPT -P INPUT   DROP
$IPT -P OUTPUT  DROP
$IPT -P FORWARD DROP
$IPT -F
$IPT -X
$IPT -t nat -F
$IPT -t nat -X

# ----- stateless
$IPT -A INPUT  -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

# ----- genéricas stateful
$IPT -A INPUT   -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT   -m state --state INVALID -j DROP

echo "O próprio gateway (o Squid vai à Internet): DNS, HTTP, HTTPS"
$IPT -A OUTPUT -p udp --sport $DYN --dport 53  -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p tcp --sport $DYN --dport 53  -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p tcp --sport $DYN --dport 80  -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p tcp --sport $DYN --dport 443 -m state --state NEW -j ACCEPT

echo "Clientes da LAN -> Squid (3128 explícito, $SQUID transparente) e SSH"
$IPT -A INPUT -i $LAN -s $REDE_LAN -p tcp --dport 3128   -m state --state NEW -j ACCEPT
$IPT -A INPUT -i $LAN -s $REDE_LAN -p tcp --dport $SQUID -m state --state NEW -j ACCEPT
$IPT -A INPUT -i $LAN -s $REDE_LAN -p tcp --dport 22     -m state --state NEW -j ACCEPT

echo "Proxy transparente: porto 80 da LAN -> Squid ($SQUID)"
$IPT -t nat -A PREROUTING -i $LAN -p tcp --dport 80 -j REDIRECT --to-ports $SQUID

echo "Resto do tráfego da LAN (DNS, HTTPS, ping) sai com NAT"
$IPT -t nat -A POSTROUTING -o $WAN -s $REDE_LAN -j MASQUERADE
$IPT -A FORWARD -i $LAN -o $WAN -p udp --dport 53  -m state --state NEW -j ACCEPT
$IPT -A FORWARD -i $LAN -o $WAN -p tcp --dport 53  -m state --state NEW -j ACCEPT
$IPT -A FORWARD -i $LAN -o $WAN -p tcp --dport 443 -m state --state NEW -j ACCEPT
$IPT -A FORWARD -i $LAN -o $WAN -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT

$IPT -L -n -v --line-numbers
$IPT -t nat -L -n -v --line-numbers
