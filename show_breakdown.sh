#!/bin/bash

if [ $# -gt 1 ]; then
    echo "Error!"
    echo "The number of arguments is wrong."
    exit 1
fi

# Initial list
if [ $# -eq 0 ]; then
    if [ -p /dev/stdin ]; then
        CURRENT_LIST="$(cat)"
    else
        echo "Error!"
        echo "There is no argument."
        echo "Usage: showbd [a one-column list]"
        exit 1
    fi
else
    CURRENT_LIST="$(cat "$1")"
fi

TOTAL=$(echo "$CURRENT_LIST" | wc -l)
BREAKDOWN=$(
    while [ -n "$(echo "$CURRENT_LIST")" ]; do
        key=$(echo "$CURRENT_LIST" | head -n 1)
        val=$(echo "$CURRENT_LIST" | grep "^$key$" | wc -l)
        printf "%3s\t" $val
        echo $key
        CURRENT_LIST=$(echo "$CURRENT_LIST" | sed -e "/^$key$/d")
    done |
        sort -rn -k1
)

# Show Result
CHKSUM=$(echo "$BREAKDOWN" | awk '{a+=$1} END{print a;}')
if [ $TOTAL != $CHKSUM ]; then
    echo "Error. The totals for all items in the breakdown do not match the original data."
    printf "The original data: %3s\n" $TOTAL
    printf "The totals for all items in the breakdown: %3s\n\n" $CHKSUM
fi
printf "%3s\t" $TOTAL
echo "Total ("$(echo "$BREAKDOWN" | wc -l) "categories)"
echo "=============================="
echo "$BREAKDOWN"
