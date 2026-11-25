#!/bin/bash
# =====================================================================
#  limit-ping-inverso.sh  -  ao contrário: a firewall NEGA 1 ping a cada
#  10 s e deixa passar os restantes.
#  O limit "apanha" 1 pacote a cada 10 s -> esse vai para DROP.
# =====================================================================
IPT=/sbin/iptables

$IPT -P INPUT   DROP
$IPT -P OUTPUT  DROP
$IPT -P FORWARD DROP
$IPT -F
$IPT -X

# ----- stateless
$IPT -A INPUT  -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

echo "Negar 1 ping a cada 10 s; os outros passam"
$IPT -A OUTPUT -p icmp --icmp-type echo-request -m limit --limit 6/minute --limit-burst 1 -j DROP
$IPT -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

# ----- genéricas stateful
$IPT -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

$IPT -L -n -v --line-numbers
