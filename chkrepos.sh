#!/bin/bash

for d in `dir -1`; do cd $d; pwd; git status; cd ..; done
