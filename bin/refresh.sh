#!/bin/bash

while read line;
do echo "$line" | ./parse.pl | GOOGLE_API_KEY='AIzaSyA15ABQUyKuW2f2_ICySTXWzP-iXL_m2P4' ./google.pl | ./save.pl;
done;
