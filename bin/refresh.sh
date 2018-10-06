#!/bin/bash

while read line;
do echo "$line" | ./parse.pl | ./google.pl | ./save.pl;
done;
