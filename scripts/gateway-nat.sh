#!/bin/bash
# =====================================================================
#  gateway-nat.sh  -  VM GATEWAY: router com NAT, tudo em modo stateful
#    LAN (host-only) ---> GATEWAY ---> WAN (NAT / Internet)
#  - SNAT (MASQUERADE): a LAN sai para a Internet com o IP do gateway
#  - DNAT: de fora, porto 80 e 2222 do gateway -> servidor interno
#  Usar:  sudo ./gateway-nat.sh
# =====================================================================
IPT=/sbin/iptables
DYN=1024:65535

# ---- AJUSTAR (ver com: ip -br a) -----------------------------------
WAN=enp0s3                 # placa NAT  (lado de fora)
LAN=enp0s8                 # placa host-only (lado de dentro)
REDE_LAN=192.168.56.0/24   # rede interna
SERVIDOR=192.168.56.20     # VM Ubuntu (servidor web + SSH)

echo "Ativar o encaminhamento de pacotes (router)"
sysctl -w net.ipv4.ip_forward=1

#####################################################################
# 1) INICIALIZAÇÃO (filter + nat)
#####################################################################
$IPT -P INPUT   DROP
$IPT -P OUTPUT  DROP
$IPT -P FORWARD DROP
$IPT -F
$IPT -X
$IPT -t nat -F
$IPT -t nat -X

#####################################################################
# 2) STATELESS
#####################################################################
$IPT -A INPUT  -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

#####################################################################
# 3) GENÉRICAS STATEFUL  (também na FORWARD!)
#####################################################################
$IPT -A INPUT   -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT   -m state --state INVALID -j DROP
$IPT -A FORWARD -m state --state INVALID -j DROP

#####################################################################
# 4) O PRÓPRIO GATEWAY
#####################################################################
echo "Gateway como cliente: DNS, HTTP, HTTPS, ping, DHCP"
$IPT -A OUTPUT -p udp --sport $DYN --dport 53  -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p tcp --sport $DYN --dport 53  -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p tcp --sport $DYN --dport 80  -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p tcp --sport $DYN --dport 443 -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p udp --sport 68 --dport 67 -m state --state NEW -j ACCEPT

echo "Gateway como servidor: SSH e ping só a partir da LAN"
$IPT -A INPUT -i $LAN -p tcp --sport $DYN --dport 22 -m state --state NEW -j ACCEPT
$IPT -A INPUT -i $LAN -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT

#####################################################################
# 5) SNAT: LAN -> Internet
#####################################################################
echo "MASQUERADE à saída da placa WAN (IP da WAN obtido por DHCP)"
$IPT -t nat -A POSTROUTING -o $WAN -s $REDE_LAN -j MASQUERADE
# com IP fixo na WAN podia ser:  -j SNAT --to-source <IP_da_WAN>

echo "FORWARD LAN -> WAN: só DNS, HTTP, HTTPS e ping"
$IPT -A FORWARD -i $LAN -o $WAN -p udp --dport 53  -m state --state NEW -j ACCEPT
$IPT -A FORWARD -i $LAN -o $WAN -p tcp --dport 53  -m state --state NEW -j ACCEPT
$IPT -A FORWARD -i $LAN -o $WAN -p tcp --dport 80  -m state --state NEW -j ACCEPT
$IPT -A FORWARD -i $LAN -o $WAN -p tcp --dport 443 -m state --state NEW -j ACCEPT
$IPT -A FORWARD -i $LAN -o $WAN -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT

#####################################################################
# 6) DNAT: Internet -> servidor interno
#    Na FORWARD já se vê o destino TRADUZIDO (IP e porto do servidor).
#####################################################################
echo "DNAT: porto 80 do gateway -> $SERVIDOR:80 (web)"
$IPT -t nat -A PREROUTING -i $WAN -p tcp --dport 80 -j DNAT --to-destination $SERVIDOR:80
$IPT -A FORWARD -i $WAN -o $LAN -p tcp -d $SERVIDOR --dport 80 -m state --state NEW -j ACCEPT

echo "DNAT: porto 2222 do gateway -> $SERVIDOR:22 (SSH)"
$IPT -t nat -A PREROUTING -i $WAN -p tcp --dport 2222 -j DNAT --to-destination $SERVIDOR:22
$IPT -A FORWARD -i $WAN -o $LAN -p tcp -d $SERVIDOR --dport 22 -m state --state NEW -j ACCEPT

echo "Gateway ON"
$IPT -L -n -v --line-numbers
$IPT -t nat -L -n -v --line-numbers
