#!/bin/bash

if [ $# -gt 1 ]; then
    echo "Error!"
    echo "The number of arguments is wrong."
    exit 1
fi
if [ $# -eq 0 ]; then
    echo "Error!"
    echo "There is no argument."
    echo "Usage: showbd [a one-column list]"
    exit 1
fi

# Initial list
CURRENT_LIST="$(cat "$1")"

TOTAL=$(echo "$CURRENT_LIST" | wc -l)
BREAKDOWN=$(
while [ -n "$(echo "$CURRENT_LIST")" ]
do
    key=$(echo "$CURRENT_LIST" | head -n 1)
    val=$(echo "$CURRENT_LIST" | grep "^$key$" | wc -l)
    printf "%3s\t" $val
    echo $key
    CURRENT_LIST=$(echo "$CURRENT_LIST" | sed -e "/^$key$/d")
done |
    sort -rn -k1
)

# Show Result
printf "%3s\t" $TOTAL
echo "Total ("$(echo "$BREAKDOWN" | wc -l) "categories)"
echo "=============================="
echo "$BREAKDOWN"
