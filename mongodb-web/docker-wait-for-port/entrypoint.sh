#!/bin/sh -e

if test -n "$WAIT_TIMEOUT"; then
    EXPIRE=$(echo "`date +%s` + $WAIT_TIMEOUT" | bc)

    printf "Waiting for mongodb port to be served "

    while [ `date +%s` -le "$EXPIRE" ]; do
            if nc -zw 1 $DB_HOST $DB_PORT >& /dev/null; then
                    printf "\ndone\n"
                    exit 0
            fi
            printf "."
            sleep 8
    done
    printf "\nERROR timeout $WAIT_TIMEOUT sec\n"
    exit 1
fi
