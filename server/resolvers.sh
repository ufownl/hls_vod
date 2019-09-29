#! /bin/sh

mkdir resolvers
echo resolver $(awk 'BEGIN{ORS=" "} $1=="nameserver" {print $2}' /etc/resolv.conf) ";" > resolvers/conf
