#!/bin/bash
# =====================================================================
#  firewall-off.sh  -  desliga a firewall
#  Política ACCEPT + apaga regras e chains de TODAS as tabelas.
#  Usar:  sudo ./firewall-off.sh
# =====================================================================
IPT=/sbin/iptables

echo "Política por omissão = ACCEPT"
$IPT -P INPUT   ACCEPT
$IPT -P OUTPUT  ACCEPT
$IPT -P FORWARD ACCEPT

echo "Apagar regras e chains personalizadas (filter, nat, mangle, raw)"
for TABELA in filter nat mangle raw; do
    $IPT -t $TABELA -F
    $IPT -t $TABELA -X
done

echo "Firewall OFF"
$IPT -L -n
