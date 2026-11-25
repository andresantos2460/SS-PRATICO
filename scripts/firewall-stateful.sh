#!/bin/bash
# =====================================================================
#  firewall-stateful.sh  -  modelo de firewall STATEFUL (iptables)
#  Usar:  chmod +x firewall-stateful.sh   &&   sudo ./firewall-stateful.sh
#
#  Regra de ouro: só se permite o 1.º pacote de cada ligação (NEW).
#  As respostas passam pelas regras genéricas ESTABLISHED,RELATED.
#    - sou CLIENTE  (eu inicio)    -> OUTPUT + --dport <porto do serviço>
#    - sou SERVIDOR (eles iniciam) -> INPUT  + --dport <porto do meu serviço>
# =====================================================================

# caminho absoluto (evita ataques à PATH)
IPT=/sbin/iptables

# portos dinâmicos = porto de origem usado pelo lado cliente
DYN=1024:65535

#####################################################################
# 1) INICIALIZAÇÃO
#####################################################################
echo "Política por omissão = DROP (o que não é permitido é proibido)"
$IPT -P INPUT   DROP
$IPT -P OUTPUT  DROP
$IPT -P FORWARD DROP

echo "Apagar regras (-F) e chains personalizadas (-X)"
$IPT -F
$IPT -X

#####################################################################
# 2) REGRAS STATELESS
#####################################################################
echo "Permitir a interface loopback"
$IPT -A INPUT  -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

#####################################################################
# 3) REGRAS GENÉRICAS STATEFUL
#####################################################################
echo "Aceitar pacotes de ligações já estabelecidas ou relacionadas"
$IPT -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "Registar (LOG) e descartar pacotes inválidos"
$IPT -A INPUT -m state --state INVALID -j LOG --log-prefix "INVALIDO: "
$IPT -A INPUT -m state --state INVALID -j DROP

#####################################################################
# 4) REGRAS STATEFUL ADICIONAIS  (só o 1.º pacote: --state NEW)
#####################################################################

# ----- como CLIENTE (a minha máquina inicia a ligação) --------------
echo "DNS (cliente)"
$IPT -A OUTPUT -p udp --sport $DYN --dport 53 -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p tcp --sport $DYN --dport 53 -m state --state NEW -j ACCEPT

echo "HTTP e HTTPS (cliente)"
$IPT -A OUTPUT -p tcp --sport $DYN --dport 80  -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p tcp --sport $DYN --dport 443 -m state --state NEW -j ACCEPT

echo "SSH (cliente)"
$IPT -A OUTPUT -p tcp --sport $DYN --dport 22 -m state --state NEW -j ACCEPT

echo "Ping (cliente)"
$IPT -A OUTPUT -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT

echo "DHCP (cliente)   bootpc=68 -> bootps=67"
$IPT -A OUTPUT -p udp --sport 68 --dport 67 -m state --state NEW -j ACCEPT

# ----- como SERVIDOR (os outros iniciam a ligação) ------------------
echo "SSH (servidor)"
$IPT -A INPUT -p tcp --sport $DYN --dport 22 -m state --state NEW -j ACCEPT

echo "Responder a ping (servidor)"
$IPT -A INPUT -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT

#####################################################################
# 5) OPCIONAL - descomentar o que o enunciado pedir
#####################################################################
# --- servidor web (Apache) só para um IP (ex.: máquina Windows)
# WIN=192.168.56.1
# $IPT -A INPUT -p tcp --sport $DYN --dport 80 -s $WIN -m state --state NEW -j ACCEPT

# --- rejeitar pedidos DNS recebidos (não sou servidor DNS)
# $IPT -A INPUT -p udp --dport 53 -m state --state NEW -j REJECT
# $IPT -A INPUT -p tcp --dport 53 -m state --state NEW -j REJECT --reject-with tcp-reset

# --- FTP (cliente): módulo que percebe a 2.ª ligação (dados) -> RELATED
# /sbin/modprobe nf_conntrack_ftp
# $IPT -t raw -A OUTPUT -p tcp --dport 21 -j CT --helper ftp   # kernel recente
# $IPT -A OUTPUT -p tcp --sport $DYN --dport 21 -m state --state NEW -j ACCEPT

# --- limitar novas ligações TCP recebidas a 5 por segundo (chain)
#     (tem de ficar ANTES das regras ACCEPT de servidor)
# $IPT -N LIMITATCP
# $IPT -A LIMITATCP -m limit --limit 5/second -j RETURN
# $IPT -A LIMITATCP -j DROP
# $IPT -I INPUT 5 -p tcp -m state --state NEW -j LIMITATCP

#####################################################################
echo "Firewall ON"
$IPT -L -n -v --line-numbers
