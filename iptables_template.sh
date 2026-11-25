#!/bin/bash

#################################
#           Student ID
#################################
#   full name:
#      number:
#################################

echo "Define iptables path"
IPT=/sbin/iptables

echo "Set default policy to DENY"
$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP

echo "Flush any existing filter rules"
$IPT -F


#################################
#  Stateless rules
#################################

echo "Allow loopback interface"
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT


# Clearly indicate, using a comment or an echo command, which specific item you are addressing.




#################################
#  Stateful rules
#################################

echo "Generic stateful rules"
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
