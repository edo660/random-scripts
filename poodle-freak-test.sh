#!/bin/bash
# USAGE: run this passing it a hosts txt file filled with hosts on each line
# will output to stdout and results.csv file
# e.g. ./script.sh hosts.txt

while read HOST;
do
# POODLE test
    POODLE=$(timeout 2 openssl s_client -connect $HOST:443 -ssl3 2> /dev/null </dev/null)
    if [ "$POODLE" == "" ]; then
            echo "$HOST,UNKNOWN,Timeout connecting to $HOST on port 443,POODLE"
            echo "$HOST,UNKNOWN,Timeout connecting to $HOST on port 443,POODLE" >> results.csv
        continue
    fi
    if echo "${POODLE}" | grep -q 'Protocol.*SSLv3'; then
        if echo "${POODLE}" | grep -q 'Cipher.*0000'; then
            echo "$HOST,NOT VULNERABLE,SSL 3 disabled,POODLE"
            echo "$HOST,NOT VULNERABLE,SSL 3 disabled,POODLE" >> results.csv
        else
            echo "$HOST,VULNERABLE,SSL 3 enabled,POODLE"
            echo "$HOST,VULNERABLE,SSL 3 enabled,POODLE" >> results.csv
        fi
    else
        echo "$HOST,UNKNOWN,SSL disabled or other error,POODLE"
        echo "$HOST,UNKNOWN,SSL disabled or other error,POODLE" >> results.csv
    fi

# FREAK test
    FREAK=$(timeout 2 openssl s_client -connect $HOST:443 -cipher EXPORT 2> /dev/null </dev/null)
    if [ "$FREAK" == "" ]; then
        echo "$HOST,UNKNOWN,Timeout connecting to $HOST on port 443,FREAK"
        echo "$HOST,UNKNOWN,Timeout connecting to $HOST on port 443,FREAK" >> results.csv
        continue
    fi
    # Check if there is an export cipher
    echo $FREAK | grep " EXP-" > /dev/null 
    if echo "${FREAK}" | grep -q ' EXP-'; then
        echo "$HOST,VULNERABLE,EXPORT detected,FREAK"
        echo "$HOST,VULNERABLE,EXPORT detected,FREAK" >> results.csv
    else
        echo "$HOST,NOT VULNERABLE,EXPORT not found,FREAK"
        echo "$HOST,NOT VULNERABLE,EXPORT not found,FREAK" >> results.csv
    fi

done < $1
