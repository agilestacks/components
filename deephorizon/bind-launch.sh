#!/bin/bash

BIND_CONFIG='/etc/bind/named.conf'
BIND_DB='/var/lib/bind'

VIEW_ZONE='k8s.agilestacks.vdc'
NUM_VIEWS='3'
SERIAL=$(date +%s)

# the cluster "native" view should be listed in the config last so the ACL rules evaluate correctly
# NAME: literally the TSIG key name but use as a descriptor
VIEW_3_NAME='k8s_native'
# KEY: the actual TSIG key
VIEW_3_KEY='8YYclPBY4CnV/SlG4OZSSMrkR5KokkvpNbbJjhIV/JemLm7J2FOcziQawHt65KUj8S2AWtOW7KWmrpBGfswWrg=='
# SUBNET: the subnet that will have access to this view (ie: ACL)
VIEW_3_SUBNET='192.168.123.0/24'
# ADDR: the servers authoritative address to advertise for the view
VIEW_3_ADDR='192.168.123.99'

VIEW_2_NAME='corp_intranet'
VIEW_2_KEY='nvKJxasg7hi40jijuqbywMwPz6JpLzTbo0VbQdPlyUWesfkhujsjBwW3jCe9LVTQk5ReEwiQil5NC4AXX2LUEg=='
VIEW_2_SUBNET='10.1.40.0/24'
VIEW_2_ADDR='10.1.40.123'

VIEW_1_NAME='public_access'
VIEW_1_KEY='9sYR1WsTBe8dpZxEoS72EKquDkvjQs51JaRuedrrYbMGVd1U3HBTC0V/0utUn/bUxoBAaVY6rGy3kUy34rOhpA=='
VIEW_1_SUBNET='215.23.24.31/26'
VIEW_1_ADDR='215.23.24.32'

VIEW_ACL=''
export TTL='$TTL'
mkdir -p /etc/bind
mkdir -p /var/lib/bind/

# intialize a new bind config
cat << EOF | envsubst > ${BIND_CONFIG}
options {
  directory "/var/cache/bind";

  dnssec-enable yes;
  dnssec-validation yes;
  auth-nxdomain no;
};

EOF

# create ACL content to be modified by each view
for i in $(seq 1 ${NUM_VIEWS}); do
    declare -n NAME=VIEW_${i}_NAME
    VIEW_ACL+="!key ${NAME};\n"
done

# create the views
for i in $(seq 1 ${NUM_VIEWS}); do
    declare -n NAME=VIEW_${i}_NAME
    declare -n KEY=VIEW_${i}_KEY
    declare -n SUBNET=VIEW_${i}_SUBNET
    declare -n ADDR=VIEW_${i}_ADDR

    ACL=$(echo -e ${VIEW_ACL} | sed "/${NAME}/s/\!/ /" | pr -T -o 4 | LANG=C sort -r)
    cat << EOF | envsubst >> ${BIND_CONFIG}
key "${NAME}" {
    algorithm hmac-sha512;
    secret "${KEY}";
};

acl ${NAME} {
${ACL}
};

view "${NAME}" {
    match-clients { ${NAME}; ${SUBNET}; };
    allow-update { ${NAME}; };
    recursion no;
    zone "${VIEW_ZONE}" {
        type master;
        file "${BIND_DB}/${NAME}.db.${VIEW_ZONE}";
    };
};

EOF

    # create the bind zone db files
    cat << EOF | envsubst > ${BIND_DB}/${NAME}.db.${VIEW_ZONE}
$TTL    60
@       IN      SOA     ns.${VIEW_ZONE}. admin.${VIEW_ZONE}. (
                      ${SERIAL} ; Serial
                         604800 ; Refresh
                          86400 ; Retry
                        2419200 ; Expire
                         604800); Negative Cache TTL
;
@            IN      NS      ns.${VIEW_ZONE}.
ns           IN      A       ${ADDR}
EOF
done
