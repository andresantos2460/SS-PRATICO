#!/bin/bash
# =====================================================================
#  limit-ping.sh  -  esta máquina só consegue ENVIAR 1 ping a cada 10 s
#  6/minuto = 1 a cada 10 segundos;  --limit-burst 1 = sem "rajada" inicial
#  O que passa do limite é descartado: esses pings ficam sem resposta
#  (algumas versões do ping mostram "sendmsg: Operation not permitted")
#
#  IMPORTANTE: estas regras ficam ANTES das genéricas ESTABLISHED,RELATED.
#  Com conntrack, do 2.º ping em diante (mesmo comando ping) os pedidos
#  já são ESTABLISHED e passavam pela regra genérica sem limite.
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

echo "Ping de saída limitado a 1 a cada 10 s"
$IPT -A OUTPUT -p icmp --icmp-type echo-request -m limit --limit 6/minute --limit-burst 1 -j ACCEPT
$IPT -A OUTPUT -p icmp --icmp-type echo-request -j DROP

# ----- genéricas stateful (o echo-reply volta como ESTABLISHED)
$IPT -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

$IPT -L -n -v --line-numbers
