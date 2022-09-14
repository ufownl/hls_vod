#! /bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mkdir -p ${DIR}/ngx_conf/resolvers
echo resolver $(awk 'BEGIN{ORS=" "} $1=="nameserver" {print $2}' /etc/resolv.conf) ";" > ${DIR}/ngx_conf/resolvers/conf
