#!/usr/bin/env bash

user_csv_columns="user_email user_role"
uniq_hosts_list_columns="K8S_provisionerHost K8S_provisionerUser K8S_provisionerPort K8S_provisionerBasePath K8S_os K8S_virt"

set_csv_columns () {
  squawk 125 "prep the columns strings for csv input"
  if [ ! -z "$1" ]; then
    KUBASH_CSV_VER=$1
  else
    KUBASH_CSV_VER=$(cat $KUBASH_CSV_VER_FILE)
  fi
  if [ "$KUBASH_CSV_VER" = '2.0.0' ]; then
    csv_columns="K8S_node K8S_role K8S_cpuCount K8S_Memory K8S_sshPort K8S_network1 K8S_mac1 K8S_ip1 K8S_routingprefix1 K8S_subnetmask1 K8S_broadcast1 K8S_gateway1 K8S_provisionerHost K8S_provisionerUser K8S_provisionerPort K8S_provisionerBasePath K8S_os K8S_virt K8S_network2 K8S_mac2 K8S_ip2 K8S_routingprefix2 K8S_subnetmask2 K8S_broadcast2 K8S_gateway2 K8S_network3 K8S_mac3 K8S_ip3 K8S_routingprefix3 K8S_subnetmask3 K8S_broadcast3 K8S_gateway3"
  elif [ "$KUBASH_CSV_VER" = '1.0.0' ]; then
    csv_columns="K8S_node K8S_role K8S_cpuCount K8S_Memory K8S_sshPort K8S_network1 K8S_mac1 K8S_ip1 K8S_provisionerHost K8S_provisionerUser K8S_provisionerPort K8S_provisionerBasePath K8S_os K8S_virt K8S_network2 K8S_mac2 K8S_ip2 K8S_network3 K8S_mac3 K8S_ip3"
  else
    croak 3  'CSV columns cannot be set CSV Version not recognized'
  fi
}
