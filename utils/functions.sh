#!/bin/bash

convert_subnet_mask_to_cidr() {
    bits=0
    for octet in $(echo $1| sed 's/\./ /g'); do 
         binbits=$(echo "obase=2; ibase=10; ${octet}"| bc | sed 's/0//g') 
         let bits+=${#binbits}
    done
    echo "/${bits}"
}
