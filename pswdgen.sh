#!/bin/bash

if [ $# -gt 1 ]; then
    echo "Error!"
    echo "The number of arguments is wrong."
    exit 1
fi
if [ $# -eq 0 ]; then
    echo "Error!"
    echo "There is no argument."
    echo "Usage: pswdgen [Number of password digits]"
    echo "Example:"
    echo "$ pswdgen 8"
    echo "6JxzXcLl"
    exit 1
fi

head /dev/urandom | tr -dc A-Za-z0-9 | head -c "$1" ; echo ''
