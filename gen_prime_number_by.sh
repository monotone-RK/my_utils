#!/bin/bash

if [ $# -gt 1 ]; then
    echo "Error!"
    echo "The number of arguments is wrong."
    exit 1
fi
if [ $# -eq 0 ]; then
    echo "Error!"
    echo "There is no argument."
    echo "Usage: gen_prime_number_by [positive integer number]"
    exit 1
fi
if [ "$1" -lt 2 ]; then
    echo "Error!"
    echo "Invalid argument (let it greater than 2)"
    exit 1
fi

NUMBER="$1"

printf "2"

for ((i=3; i<="$NUMBER"; i+=2)) do
    is_prime_number=true
    range=`echo "sqrt("$i")"|bc`
    for ((j=3; j<="$range"; j+=2)) do
	mod_result=$(echo $(( $i % $j)))
	if [ $mod_result -eq 0 ]; then
	    is_prime_number=false
	    break
	fi
    done
    if "$is_prime_number" ; then
	printf ", $i"
    fi
done

printf "\n"
