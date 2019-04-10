#!/usr/bin/env bash

taint_storage () {
  squawk 1 " taint_storage $@"
  count_storage=0
  for storage_node in "$@"
  do
    squawk 5 "kubectl --kubeconfig=$KUBECONFIG taint --overwrite node $storage_node storageOnly=true:PreferNoSchedule"
    kubectl --kubeconfig=$KUBECONFIG taint --overwrite node $storage_node storageOnly=true:PreferNoSchedule
    squawk 5 "kubectl --kubeconfig=$KUBECONFIG label --overwrite node $storage_node storage=true"
    kubectl --kubeconfig=$KUBECONFIG label --overwrite node $storage_node storage=true
    ((++count_storage))
  done
  if [[ $count_storage -eq 0 ]]; then
    croak 3  'No storage nodes found!'
  fi
}

taint_all_storage () {
  squawk 1 " taint_all_storage $@"
  count_all_storage=0
  nodes_to_taint=' '
  while IFS="," read -r $csv_columns
  do
    squawk 185 "ROLE $K8S_role $K8S_user $K8S_ip1 $K8S_sshPort"
    if [[ "$K8S_role" = "storage" ]]; then
      squawk 5 "ROLE $K8S_role $K8S_user $K8S_ip1 $K8S_sshPort"
      squawk 121 "nodes_to_taint $K8S_node $nodes_to_taint"
      new_nodes_to_taint="$K8S_node $nodes_to_taint"
      nodes_to_taint="$new_nodes_to_taint"
      ((++count_all_storage))
    fi
  done <<< "$kubash_hosts_csv_slurped"
  echo "count_all_storage $count_all_storage"
  if [[ $count_all_storage -eq 0 ]]; then
    squawk 150 "slurpy -----> $(echo $kubash_hosts_csv_slurped)"
    croak 3  'No storage nodes found!!!'
  else
    squawk 185 "ROLE $K8S_role $K8S_user $K8S_ip1 $K8S_sshPort"
    squawk 101 "taint these nodes_to_taint=$K8S_node $nodes_to_taint"
    taint_storage $nodes_to_taint
  fi
}

mount_all_iscsi_targets () {
  squawk 1 "mount all iscsi targets $@"
  count_iscsi_targets=0
  nodes_to_taint=' '
  while IFS="," read -r $csv_columns
  do
    squawk 185 "ROLE $K8S_role $K8S_user $K8S_ip1 $K8S_sshPort"
    if [[ "$K8S_role" = "storage" ]]; then
      if [[ ! -z "$K8S_iscsitarget" ]]; then
        ((++count_iscsi_targets))
        command2run="iscsiadm -m discovery -t sendtargets -p ${K8S_iscsitarget}"
        sudo_command $K8S_sshPort $K8S_user $K8S_ip1 "$command2run"
        if [[ ! -z "$K8S_iscsichapusername" ]]; then
            croak 3 'chapusername supplied not implemented yet!!!'
          if [[ ! -z "$K8S_iscsichappassword" ]]; then
          else
            croak 3 'chapusername supplied without a chappassword!!!'
          fi
        fi
        command2run="iscsiadm -m node -l ${K8S_iscsitarget}"
        sudo_command $K8S_sshPort $K8S_user $K8S_ip1 "$command2run"
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"
}
