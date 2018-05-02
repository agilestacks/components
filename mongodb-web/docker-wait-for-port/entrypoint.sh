#!/bin/sh -e
PORT=${PORT:-$DEFAULT_PORT}
if test -n "$WAIT_TIMEOUT" && test -n "$HOST" && test -n "$PORT"; then
	PORT_NAME=${PORT_NAME:-"$HOST:$PORT"}
	EXPIRE=$(echo "`date +%s` + $WAIT_TIMEOUT" | bc)
        CHECK_INTERVAL=${CHECK_INTERVAL:-8}

	printf "Waiting for $PORT_NAME to be served "

	while [ `date +%s` -le "$EXPIRE" ]; do
			if nc -zw 1 $HOST $PORT >& /dev/null; then
					printf "\ndone\n"
					exit 0
			fi
			printf "."
			sleep $CHECK_INTERVAL
	done
	printf "\nERROR timeout $WAIT_TIMEOUT sec\n"
	exit 1
fi
