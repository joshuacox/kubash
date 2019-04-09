#!/usr/bin/env bash

yaml2cluster () {
  squawk 15 "yaml2cluster"
  yaml2cluster_tmp=$(mktemp -d)
  if [[ -z "$1" ]]; then
    croak 3  'yaml2cluster requires an argument'
  fi
  this_yaml=$1
  this_json=$yaml2cluster_tmp/this.json
  yaml2json $this_yaml > $this_json
  json2cluster $this_json
  rm $this_json
  rm -Rf $yaml2cluster_tmp
}

json2cluster () {
  squawk 15 "json2cluster"
  json2cluster_tmp=$(mktemp -d)
  if [[ -z "$1" ]]; then
    croak 3  'json2cluster requires an argument'
  fi
  this_json=$1

  if [[ -e $KUBASH_DIR/clusters/$KUBASH_CLUSTER_NAME ]]; then
    horizontal_rule
    echo "The cluster directory already exists! $KUBASH_DIR/clusters/$KUBASH_CLUSTER_NAME"
    horizontal_rule
    exit 1
  fi

  # csv_version
  # should be a string not an int!
  jq -r '.csv_version | "\(.)" ' \
    $this_json > $json2cluster_tmp/csv_version
  # kubernetes_version
  # should be a string not an int!
  jq -r '.kubernetes_version | "\(.)" ' \
    $this_json > $json2cluster_tmp/kubernetes_version

  KUBASH_CSV_VER=$(cat $json2cluster_tmp/csv_version)
  squawk 11 "CSV_VER=$KUBASH_CSV_VER"
  if [ "$KUBASH_CSV_VER" = '2.0.0' ]; then
    # provision.csv
    jq -r \
      '.hosts[] | "\(.hostname),\(.role),\(.cpuCount),\(.Memory),\(.sshPort),\(.network1.network),\(.network1.mac),\(.network1.ip),\(.network1.routingprefix),\(.network1.subnetmask),\(.network1.broadcast),\(.network1.gateway),\(.provisioner.Host),\(.provisioner.User),\(.provisioner.Port),\(.provisioner.BasePath),\(.os),\(.virt),\(.network2.network),\(.network2.mac),\(.network2.ip),\(.network2.routingprefix),\(.network2.subnetmask),\(.network2.broadcast),\(.network2.gateway),\(.network3.network),\(.network3.mac),\(.network3.ip),\(.network3.routingprefix),\(.network3.subnetmask),\(.network3.broadcast),\(.network3.gateway)"' \
      $this_json >  $json2cluster_tmp/tmp.csv
  elif [ "$KUBASH_CSV_VER" = '1.0.0' ]; then
    # provision.csv
    jq -r \
      '.hosts[] | "\(.hostname),\(.role),\(.cpuCount),\(.Memory),\(.sshPort),\(.network1.network),\(.network1.mac),\(.network1.ip),\(.provisioner.Host),\(.provisioner.User),\(.provisioner.Port),\(.provisioner.BasePath),\(.os),\(.virt),\(.network2.network),\(.network2.mac),\(.network2.ip),\(.network3.network),\(.network3.mac),\(.network3.ip)"' \
      $this_json >  $json2cluster_tmp/tmp.csv
  else
    croak 3  'CSV columns cannot be set CSV Version not recognized'
  fi

  set_csv_columns $KUBASH_CSV_VER
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_mac1" == 'null' ]]; then
      K8S_mac1=$(VERBOSITY=0 kubash --verbosity=1 genmac)
    fi
    if [[ "$K8S_network2" != 'null' ]]; then
      if [[ "$K8S_mac2" == 'null' ]]; then
        K8S_mac2=$(VERBOSITY=0 kubash --verbosity=1 genmac)
      fi
    fi
    if [[ "$K8S_network3" != 'null' ]]; then
      if [[ "$K8S_mac3" == 'null' ]]; then
        K8S_mac3=$(VERBOSITY=0 kubash --verbosity=1 genmac)
      fi
    fi
    if [ "$KUBASH_CSV_VER" = '2.0.0' ]; then
      squawk 6 "$K8S_node,$K8S_role,$K8S_cpuCount,$K8S_Memory,$K8S_sshPort,$K8S_network1,$K8S_mac1,$K8S_ip1,$K8S_routingprefix1,$K8S_subnetmask1,$K8S_broadcast1,$K8S_gateway1,$K8S_provisionerHost,$K8S_provisionerUser,$K8S_provisionerPort,$K8S_provisionerBasePath,$K8S_os,$K8S_virt,$K8S_network2,$K8S_mac2,$K8S_ip2,$K8S_routingprefix2,$K8S_subnetmask2,$K8S_broadcast2,$K8S_gateway2,$K8S_network3,$K8S_mac3,$K8S_ip3,$K8S_routingprefix3,$K8S_subnetmask3,$K8S_broadcast3,$K8S_gateway3"
      echo "$K8S_node,$K8S_role,$K8S_cpuCount,$K8S_Memory,$K8S_sshPort,$K8S_network1,$K8S_mac1,$K8S_ip1,$K8S_routingprefix1,$K8S_subnetmask1,$K8S_broadcast1,$K8S_gateway1,$K8S_provisionerHost,$K8S_provisionerUser,$K8S_provisionerPort,$K8S_provisionerBasePath,$K8S_os,$K8S_virt,$K8S_network2,$K8S_mac2,$K8S_ip2,$K8S_routingprefix2,$K8S_subnetmask2,$K8S_broadcast2,$K8S_gateway2,$K8S_network3,$K8S_mac3,$K8S_ip3,$K8S_routingprefix3,$K8S_subnetmask3,$K8S_broadcast3,$K8S_gateway3" \
        >>  $json2cluster_tmp/provision.csv
    elif [ "$KUBASH_CSV_VER" = '1.0.0' ]; then
      echo "$K8S_node,$K8S_role,$K8S_cpuCount,$K8S_Memory,$K8S_sshPort,$K8S_network1,$K8S_mac1,$K8S_ip1,$K8S_provisionerHost,$K8S_provisionerUser,$K8S_provisionerPort,$K8S_provisionerBasePath,$K8S_os,$K8S_virt,$K8S_network2,$K8S_mac2,$K8S_ip2,$K8S_network3,$K8S_mac3,$K8S_ip3" \
        >>  $json2cluster_tmp/provision.csv
    else
      croak 3  'CSV columns cannot be set CSV Version not recognized'
    fi
  done < "$json2cluster_tmp/tmp.csv"

  rm $json2cluster_tmp/tmp.csv
  squawk 5 "$(cat $json2cluster_tmp/provision.csv)"

  # ca-data.yaml
#### BEGIN --> Indentation break warning <-- BEGIN
  jq -r \
    '.ca[] | "CERT_COMMON_NAME: \(.CERT_COMMON_NAME)
CERT_COUNTRY: \(.CERT_COUNTRY)
CERT_LOCALITY: \(.CERT_LOCALITY)
CERT_ORGANISATION: \(.CERT_ORGANISATION)
CERT_STATE: \(.CERT_STATE)
CERT_ORG_UNIT: \(.CERT_ORG_UNIT)"' \
    $this_json >  $json2cluster_tmp/ca-data.yaml
#### END --> Indentation break warning <-- END
  squawk 5 "$(cat $json2cluster_tmp/ca-data.yaml)"

  # net_set
  jq -r '.net_set | "\(.)" ' \
    $this_json >  $json2cluster_tmp/net_set
  squawk 7 "$(cat $json2cluster_tmp/net_set)"

  # users.csv
  jq -r '.users | to_entries[] | "\(.key),\(.value.role)"' \
    $this_json >  $json2cluster_tmp/users.csv


  $CP_CMD $KUBASH_DIR/templates/ca-csr.json $json2cluster_tmp/
  $CP_CMD $KUBASH_DIR/templates/ca-config.json $json2cluster_tmp/
  $CP_CMD $KUBASH_DIR/templates/client.json $json2cluster_tmp/

  $MV_CMD $json2cluster_tmp $KUBASH_DIR/clusters/$KUBASH_CLUSTER_NAME
}
