#!/bin/bash

while read d; do cd "$d" || exit; pwd; git pull; cd ..; echo "--------------------------------------------------"; done < <(dir -1)
