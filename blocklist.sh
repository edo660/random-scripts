#!/bin/bash
# Script to download the set blocklists (format of one IP per line)
# and add them to iptables to block incoming traffic from them
# Note: requires ipset
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; export PATH

check_exists() {
    [ $# -lt 1 -o $# -gt 2 ] && {
        echo "Usage: chain_exists <chain_name> [table]" >&2
        return 1
    }
    local chain_name="$1" ; shift
    [ $# -eq 1 ] && local table="--table $1"
    iptables $table -n --list "$chain_name" >/dev/null 2>&1
}

# Blacklist names & URLs array
declare -A blacklists
blacklists[tor-exit-nodes]="https://www.dan.me.uk/torlist/?exit"
blacklists[blocklist-de]="https://lists.blocklist.de/lists/ssh.txt"
# blacklists[key]="url"
# etc...

for key in ${!blacklists[@]}; do

    DATE=$(date +"%b %d %T")

    # Download blacklist
    wget --quiet --output-document=/tmp/blacklist_$key -w 5 ${blacklists[$key]}

    # create iptable rules & ipset if they don't exist
    if ! check_exists $key; then
        ipset create $key hash:ip maxelem 400000

        #iptables -D INPUT -m set --match-set $key src -j $key # Delete link to list chain from INPUT
        #iptables -F $key # Flush list chain if existed
        #iptables -X $key # Delete list chain if existed
        iptables -N $key # Create list chain

        # Add rules to iptables
        # uncomment the below 3 if you want logging enabled
        #iptables -A $key -p tcp -m limit --limit 5/min -j LOG --log-prefix "Denied $key TCP: " --log-level 7
        #iptables -A $key -p udp -m limit --limit 5/min -j LOG --log-prefix "Denied $key UDP: " --log-level 7
        #iptables -A $key -p icmp -m limit --limit 5/min -j LOG --log-prefix "Denied $key ICMP: " --log-level 7
        iptables -A $key -j DROP # Drop after logging
        iptables -I INPUT 2 -m set --match-set $key src -j $key # Link to iptables INPUT chain, position #2
        iptables -I OUTPUT 2 -m set --match-set $key src -j $key # Link to iptables INPUT chain, position #2
        iptables -I FORWARD 1 -m set --match-set $key src -j $key # Link to iptables INPUT chain, position #1

    fi
    ipset flush $key

    while read line; do
        # Add addresses from list to ipset
        ipset add $key $line -quiet
    done < <(cat /tmp/blacklist_$key | sed '1,2d' | sed s/.*://)

    # Log to syslog how many IPs we added to be blocked
    IPADDS=`ipset --list $key | wc -l`
    let "c=$IPADDS - 7"
    echo "$DATE $(hostname) block-tor-exit-nodes.sh: $c IP's from list $key added to block list" >> /var/log/syslog

done
