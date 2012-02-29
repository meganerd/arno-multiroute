#!/bin/bash
## Multiple Path Routing
## Variables

## Internal Interface, IP, and Network
IF0=eth0
IP0=10.0.0.252
P0_NET="10.0.0.0/24"

## First (1) External Interface, IP, Gateway, and Network
IF1=eth1
IP1=192.168.1.2
GW1=192.168.1.1
P1_NET="192.168.1.0/24"

## Second (2) External Interface, IP, Gateway, and Network
IF2=wlan0
IP2=192.168.197.240
GW2=192.168.197.252
P2_NET="192.168.197.0/24"

## Third (3) External Interface, IP,Gateway, and Network
IF3=ath0
IP3=192.168.20.142
GW3=192.168.20.1
P3_NET=192.168.20.0

## Add tables to routing table
#echo "200	T1"  >> /etc/iproute2/rt_tables
#echo "201	T2"  >> /etc/iproute2/rt_tables
#echo "202	T3"  >> /etc/iproute2/rt_tables

## Add SFQ to all interfaces.  While not routing related, I put SFQ on all the external interfaces to ensure that 
## a single connection does not saturate any given link

echo "Add SFQ to all interfaces." 
tc qdisc add dev $IF0 root sfq perturb 10
tc qdisc add dev $IF1 root sfq perturb 10
tc qdisc add dev $IF2 root sfq perturb 10
tc qdisc add dev $IF3 root sfq perturb 10

## Script Logic
ip route flush table T1
ip route add $P1_NET dev $IF1 src $IP1 table T1
ip route add default via $GW1 table T1
ip route flush table T2
ip route add $P2_NET dev $IF2 src $IP2 table T2
ip route add default via $GW2 table T2
ip route flush table T3
ip route add $P3_NET dev $IF3 src $IP3 table T3
ip route add default via $GW3 table T3

echo "Add routes for external Interface networks"
echo "Route for $IF1"
ip route add $P1_NET dev $IF1 src $IP1
echo "Route for $IF2"
ip route add $P2_NET dev $IF2 src $IP2
echo "Route for $IF3"
ip route add $P3_NET dev $IF3 src $IP3

echo "Add default route via $GW1"
ip route add default via $GW1

echo "Add rules for gateways to tables"
echo "Rule for $IP1 and table T1"
ip rule add from $IP1 table T1
echo "Rule for $IP2 and table T2"
ip rule add from $IP2 table T2
echo "Rule for $IP3 and table T3"
 ip rule add from $IP3 table T3

echo "Link external interface to interface for table T1"
ip route add $P0_NET     dev $IF0 table T1
ip route add $P2_NET     dev $IF2 table T1
ip route add $P3_NET	 dev $IF3 table T1
ip route add 127.0.0.0/8 dev lo   table T1

echo "Link external interface to interface for table T2"
ip route add $P0_NET     dev $IF0 table T2
ip route add $P1_NET     dev $IF1 table T2
ip route add $P3_NET	 dev $IF3 table T2
ip route add 127.0.0.0/8 dev lo   table T2

ip route add $P0_NET     dev $IF0 table T3
ip route add $P1_NET     dev $IF1 table T3
ip route add $P2_NET     dev $IF3 table T3
ip route add 127.0.0.0/8 dev lo   table T3

## Set up multipath
echo "Deleting current default route"
ip route del default
echo "Setting multipath default route"
ip route add default scope global nexthop via $GW1 dev $IF1 weight 1 nexthop via $GW2 dev $IF2 weight 1 nexthop via $GW3 dev $IF3 weight 1
echo "Done!"
echo "Current route table looks like the following:"
ip route
