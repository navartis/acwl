#!/bin/bash

set -euo pipefail

CURRENT_ABS_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"

source $CURRENT_ABS_PATH/functions.sh

while read -r mask_record
do
  network_addr=$(echo $mask_record | cut -d " " -f 1)
  network_mask=$(echo $mask_record | cut -d " " -f 2)
  cidr=$(convert_subnet_mask_to_cidr $network_mask)
  echo $network_addr$cidr
done < $1
