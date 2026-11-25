#!/bin/bash
# =====================================================================
#  redirect-2022.sh  -  SSH acessível de fora só pelo porto 2022
#  2022 -> 22 com REDIRECT (nat) + bloquear o acesso direto ao 22 (raw)
#  Testar de OUTRA máquina:  ssh -p 2022 user@IP   (funciona)
#                            ssh user@IP           (não responde)
# =====================================================================
IPT=/sbin/iptables
DYN=1024:65535

#####################################################################
# 1) INICIALIZAÇÃO (filter + nat + raw)
#####################################################################
$IPT -P INPUT   DROP
$IPT -P OUTPUT  DROP
$IPT -P FORWARD DROP
$IPT -F
$IPT -X
$IPT -t nat -F
$IPT -t raw -F

#####################################################################
# 2) STATELESS + 3) GENÉRICAS STATEFUL
#####################################################################
$IPT -A INPUT  -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT
$IPT -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT  -m state --state INVALID -j DROP

#####################################################################
# 4) STATEFUL
#####################################################################
echo "SSH (servidor): a filter já vê o porto TRADUZIDO (22)"
$IPT -A INPUT -p tcp --sport $DYN --dport 22 -m state --state NEW -j ACCEPT

echo "Redirecionar 2022 -> 22 (tabela nat, chain PREROUTING)"
$IPT -t nat -A PREROUTING -p tcp --dport 2022 -j REDIRECT --to-ports 22

echo "Negar o 22 a quem vem de fora (tabela raw = antes do NAT)"
$IPT -t raw -A PREROUTING ! -i lo -p tcp --dport 22 -j DROP

# Alternativa sem a tabela raw (aceita só o que ORIGINALMENTE ia para 2022),
# em vez da regra "SSH (servidor)" acima:
# $IPT -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW --ctorigdstport 2022 -j ACCEPT

$IPT -t nat -L -n -v
$IPT -t raw -L -n -v
$IPT -L -n -v --line-numbers
