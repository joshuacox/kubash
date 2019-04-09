#!/usr/bin/env bash

horizontal_rule () {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

# Check if a command exists
check_cmd () {
  if ! test_cmd_loc="$(type -p "$1")" || [[ -z "$test_cmd_loc" ]]; then
    horizontal_rule
    echo "$1 was not found in your path!"
    croak 3  "To proceed please install $1 to your path and try again!"
  fi
}

check_cmd mktemp

# Check if a file exists and is writable
check_file () {
  if [[ -w "$1" ]]; then
    croak 3  "$1 was not writable!"
  fi
}

chkdir () {
  if [[ ! -w "$1" ]] ; then
    sudo mkdir -p $1
    sudo chown $USER $1
  fi
  if [[ ! -w "$1" ]] ; then
    echo "Cannot write to $1, please check your permissions"
    exit 2
  fi
}

killtmp () {
  cd
  rm -Rf $TMP
}

# these vars are used by the following functions
LINE_TO_ADD=''
TARGET_FILE_FOR_ADD=$HOME/.profile

check_if_line_exists()
{
  squawk 7 " Checking for '$LINE_TO_ADD'  in $TARGET_FILE_FOR_ADD"
  grep -qsFx "$LINE_TO_ADD" $TARGET_FILE_FOR_ADD
}

add_line_to()
{
  squawk 105 " Adding '$LINE_TO_ADD'  to $TARGET_FILE_FOR_ADD"
  TARGET_FILE=$TARGET_FILE_FOR_ADD
    [[ -w "$TARGET_FILE" ]] || TARGET_FILE=$TARGET_FILE_FOR_ADD
    printf "%s\n" "$LINE_TO_ADD" >> "$TARGET_FILE"
}

genmac () {
  # Generate a mac address
  hexchars="0123456789ABCDEF"
  : ${DEFAULT_MAC_ADDRESS_BLOCK:=52:54:00}

  if [[ ! -z "$1" ]]; then
    DEFAULT_MAC_ADDRESS_BLOCK=$1
  fi

  end=$( for i in {1..6} ; do echo -n ${hexchars:$(( $RANDOM % 16 )):1} ; done | sed -e 's/\(..\)/:\1/g' )

  echo "$DEFAULT_MAC_ADDRESS_BLOCK$end" >&3
}

set_verbosity () {
  if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    VERBOSITY=0
  else
    VERBOSITY=$1
  fi
  squawk 5 " verbosity is now $VERBOSITY"
}

increase_verbosity () {
  ((++VERBOSITY))
  squawk 5 " verbosity is now $VERBOSITY"
}

set_name () {
  squawk 9 "set_name $1"
  squawk 8 "Kubash will now work with the $1 cluster"
  KUBASH_CLUSTER_NAME="$1"
  KUBASH_CLUSTER_DIR=$KUBASH_CLUSTERS_DIR/$KUBASH_CLUSTER_NAME
  KUBASH_CLUSTER_CONFIG=$KUBASH_CLUSTER_DIR/config
  export KUBECONFIG=$KUBASH_CLUSTER_CONFIG
  KUBASH_HOSTS_CSV=$KUBASH_CLUSTER_DIR/hosts.csv
  KUBASH_ANSIBLE_HOSTS=$KUBASH_CLUSTER_DIR/hosts
  KUBASH_KUBESPRAY_HOSTS=$KUBASH_CLUSTER_DIR/inventory/hosts.ini
  KUBASH_PROVISION_CSV=$KUBASH_CLUSTER_DIR/provision.csv
  KUBASH_USERS_CSV=$KUBASH_CLUSTER_DIR/users.csv
  KUBASH_CSV_VER_FILE=$KUBASH_CLUSTER_DIR/csv_version
  net_set
  if [[ -e $KUBASH_CLUSTER_DIR/csv_version ]]; then
    set_csv_columns
    if [[ -e $KUBASH_CLUSTER_DIR/provision.csv ]]; then
      provision_csv_slurp
      squawk 160 "slurpy -----> $(echo $kubash_provision_csv_slurped)"
    fi
    if [[ -e $KUBASH_CLUSTER_DIR/hosts.csv ]]; then
      hosts_csv_slurp
      squawk 150 "slurpy -----> $(echo $kubash_hosts_csv_slurped)"
      while IFS="," read -r $csv_columns
      do
        if [[ "$K8S_role" == 'etcd' ]]; then
          export MASTERS_AS_ETCD="false"
        elif [[ "$K8S_role" == "primary_master" ]]; then
          get_major_minor_kube_version $K8S_user $K8S_ip1  $K8S_node $K8S_sshPort
        fi
      done <<< "$kubash_hosts_csv_slurped"
    fi
  fi
}

rolero () {
  squawk 2 "rolero $@"
  node_name=$1
  NODE_ROLE=$2

  result=$(kubectl --kubeconfig=$KUBECONFIG label --overwrite node $node_name node-role.kubernetes.io/$NODE_ROLE=)
  squawk 4 "Result = $result"
}
