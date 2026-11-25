#!/bin/bash
# =====================================================================
#  facebook-block.sh  -  web permitida EXCETO para o Facebook (stateful)
#  Precisa do ficheiro com as redes do Facebook (uma por linha), ex.:
#    whois -h whois.radb.net -- '-i origin AS32934' | grep ^route: \
#        | awk '{print $2}' > Facebook-all-ipv4.txt
#  Usar:  sudo ./facebook-block.sh      (demora uns segundos: ~350 regras)
# =====================================================================
IPT=/sbin/iptables
DYN=1024:65535
LISTA=Facebook-all-ipv4.txt

if [ ! -f "$LISTA" ]; then
    echo "Ficheiro $LISTA não encontrado!"
    exit 1
fi

#####################################################################
# 1) INICIALIZAÇÃO + 2) STATELESS + 3) GENÉRICAS STATEFUL
#####################################################################
$IPT -P INPUT   DROP
$IPT -P OUTPUT  DROP
$IPT -P FORWARD DROP
$IPT -F
$IPT -X

$IPT -A INPUT  -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

$IPT -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT  -m state --state INVALID -j DROP

#####################################################################
# 4) STATEFUL
#####################################################################
echo "DNS (cliente) - todos os pedidos"
$IPT -A OUTPUT -p udp --sport $DYN --dport 53 -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p tcp --sport $DYN --dport 53 -m state --state NEW -j ACCEPT

echo "SSH (cliente e servidor)"
$IPT -A OUTPUT -p tcp --sport $DYN --dport 22 -m state --state NEW -j ACCEPT
$IPT -A INPUT  -p tcp --sport $DYN --dport 22 -m state --state NEW -j ACCEPT

echo "Chain FACEBOOK: rejeita ligações para as redes da lista"
$IPT -N FACEBOOK
while read -r REDE || [ -n "$REDE" ]; do
    [ -z "$REDE" ] && continue
    $IPT -A FACEBOOK -d "$REDE" -j REJECT
done < "$LISTA"
# se o destino não estiver na lista, o pacote chega ao fim da chain
# e volta (RETURN) à OUTPUT, onde é aceite pelas regras seguintes

echo "Web (cliente): primeiro passa pela chain FACEBOOK, depois é aceite"
$IPT -A OUTPUT -p tcp -m multiport --dports 80,443 -m state --state NEW -j FACEBOOK
$IPT -A OUTPUT -p udp --dport 443 -m state --state NEW -j FACEBOOK
$IPT -A OUTPUT -p tcp --sport $DYN -m multiport --dports 80,443 -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p udp --sport $DYN --dport 443 -m state --state NEW -j ACCEPT

echo "Regras na chain FACEBOOK: $($IPT -S FACEBOOK | grep -c REJECT)"
$IPT -L OUTPUT -n -v --line-numbers
