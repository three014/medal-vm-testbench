#!/bin/bash

usage() {
  echo "Usage: `basename $0` -o [OUTPUT_FILE] -u [USERDATA_FILE] -m [METADATA_FILE]"
}

output=""
userdata=""
metadata=""

while getopts ':o:u:m:' OPTION; do
  case ${OPTION} in
    o)
      output=${OPTARG}
      ;;
    u)
      userdata=${OPTARG}
      ;;
    m)
      metadata=${OPTARG}
      ;;
    *)
      usage
      exit 1
  esac
done

if [ "${output}" = "" ]; then
  usage
  exit 1
fi

if [ "${metadata}" = "" ]; then
  usage
  exit 1
fi

if [ "${userdata}" = "" ]; then
  usage
  exit 1
fi

genisoimage -output ${output} -volid cidata -joliet -rock ${userdata} ${metadata}
