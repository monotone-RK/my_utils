#!/bin/bash

if [ $# -gt 1 ]; then
    echo "Error!"
    echo "Too many arguments."
    exit 1
fi
if [ $# -eq 0 ]; then
    echo "Error!"
    echo "There is no argument."
    echo "Usage: prime_factorize [positive integer number]"
    exit 1
fi
if [ "$1" -lt 2 ]; then
    echo "Error!"
    echo "Invalid argument (let it greater than 2)"
    exit 1
fi

NUMBER="$1"
FACTORS=()

for ((i=2; (i*i)<="$NUMBER"; i++)) do
    for ((j=0; "$(echo $(( $NUMBER % $i)))"==0; j++)) do
	NUMBER=$(echo $(( $NUMBER / $i)))
    done
    if [ $j -ne 0 ]; then
	FACTORS+=("$i^$j")
    fi
done

if [ $NUMBER -ne 1 ]; then
    FACTORS+=("$NUMBER^1")
fi

RESULT=$(echo ${FACTORS[@]} | sed -e "s/ /, /g")
printf "$RESULT\n"
