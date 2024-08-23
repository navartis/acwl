# #!/bin/bash

set -euo pipefail

usage() {
	echo
	echo "Usage: $0 [options]"
	echo
	echo "  Options:"
	echo
	echo "    -h, --help                       -  Print help."
	echo
	echo "    -i, --in-file                    -  Source file of line by line routes in \"NETWORK_ADDRESS DOT_DECIMAL_MASK\" format."
	echo
	echo "    -o, --out-file                   -  Destination file of routes."
	echo
	echo "    -e, --on-success                 -  Path to executable if routes changed or --force-on-success option used."
	echo
	echo "    -f, --force-on-success           -  Force execution of --on-success even routes not changed."
}

OPT_FORCE_ON_SUCCESS=false
OPT_OUT_FILE=""
OPT_ON_SUCCESS=""
OPT_IN_FILE=""

ENV_ON_SUCCESS_IS_READY=false

on_misuse() {
	usage
	exit 1
}

on_option_required_not_empty() {
	print_error "Error: $1 is required. Should not be empty."
	usage
	exit 3
}

print_error() {
	echo "Error: $1"
}

get_file_fingerprint() {
	echo $(shasum -a 256 $1)
}

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -i|--in-file)
            shift
            test $# -gt 0 || on_misuse
            OPT_IN_FILE="$1"
            shift
            ;;
        -o|--out-file)
            shift
            test $# -gt 0 || on_misuse
            OPT_OUT_FILE="$1"
            shift
            ;;
        -s|--on-success)
            shift
            test $# -gt 0 || on_misuse
            OPT_ON_SUCCESS="$1"
            shift
            ;;
        -f|--force-on-success)
            OPT_FORCE_ON_SUCCESS=true
            break
            ;;
        # --)
        #     shift
        #     break
        #     ;;
        *)
            on_misuse
            ;;
    esac
done

if [[ -z "$OPT_OUT_FILE" ]]; then
    on_option_required_not_empty "--out-file"
fi

if [[ -z "$OPT_IN_FILE" ]]; then
	on_option_required_not_empty "--in-file"
fi

if ! [[ -f "$OPT_IN_FILE" ]]; then
  print_error "--in-file \"$OPT_IN_FILE\" does not exist."
  exit 4
fi

if ! [[ -f "$OPT_OUT_FILE" ]]; then
	out_dir="$(dirname "${OPT_OUT_FILE}")"
	mkdir -p $out_dir && touch "$OPT_OUT_FILE"
fi

if [[ -z "$OPT_ON_SUCCESS" ]]; then
	ENV_ON_SUCCESS_IS_READY=false
else
	if ! [[ -x "$OPT_ON_SUCCESS" ]]; then
		print_error "--on-success \"$OPT_ON_SUCCESS\" does not exist or not executable."
		exit 5
	fi

	ENV_ON_SUCCESS_IS_READY=true
fi

get_out_file_fingerprint() {
	echo $(get_file_fingerprint $OPT_OUT_FILE)
}

before_out_fingerprint=$(get_out_file_fingerprint)

awk 'NF { $1=$1; print }' $OPT_IN_FILE | 
grep -E  '^([0-9]{1,3}\.){3}[0-9]{1,3}\ ([0-9]{1,3}\.){3}[0-9]{1,3}$' | 
sort | 
uniq | 
awk '{print "push \"route "$0"\""}' -  >$OPT_OUT_FILE

after_out_fingerprint=$(get_out_file_fingerprint)


if [[ $ENV_ON_SUCCESS_IS_READY == true ]] && [[ "$before_out_fingerprint" != "$after_out_fingerprint" ]]; then
	"$OPT_ON_SUCCESS"
fi

if [[ $OPT_FORCE_ON_SUCCESS == true ]]; then
	if [[ $ENV_ON_SUCCESS_IS_READY == false ]]; then
		print_error "--on-success value in conjunction with --force-on-success should be defined and valid."
		usage
		exit 6
	fi 

	"$OPT_ON_SUCCESS"
fi
