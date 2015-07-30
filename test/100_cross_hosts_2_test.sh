#! /bin/bash

. ./config.sh

C1=10.2.1.4
C2=10.2.1.7
UNIVERSE=10.2.0.0/16
SUBNET_1=10.2.2.0/24
SUBNET_2=10.2.3.0/24

start_suite "Ping over cross-host weave network (with and without IPAM)"

weave_on $HOST1 launch --ipalloc-range $UNIVERSE --ipalloc-default-subnet $SUBNET_1
weave_on $HOST2 launch --ipalloc-range $UNIVERSE --ipalloc-default-subnet $SUBNET_1 $HOST1

start_container $HOST1    $C1/24     --name=c1
start_container $HOST2 ip:$C2/24     --name=c2
assert_raises "exec_on $HOST1 c1 $PING $C2"

start_container $HOST1               --name=c3
start_container $HOST2 net:default   --name=c4
C4=$(container_ip $HOST2 c4)
assert_raises "exec_on $HOST1 c3 $PING $C4"

start_container $HOST1 net:$SUBNET_2 --name=c5
start_container $HOST2 net:$SUBNET_2 --name=c6
C6=$(container_ip $HOST2 c6)
assert_raises "exec_on $HOST1 c5 $PING $C6"

# check large packets get through. The first attempt typically fails,
# since the PMTU hasn't been discovered yet. The 2nd attempt should
# succeed.
exec_on $HOST1 c1 $PING -s 65000 $C2 2>&1 1>/dev/null || true
assert_raises "exec_on $HOST1 c1 $PING -s 65000 $C2"

end_suite