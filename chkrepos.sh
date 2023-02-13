#!/bin/bash

while read d; do cd "$d" || exit; pwd; git status; cd ..; echo "--------------------------------------------------"; done < <(dir -1)
