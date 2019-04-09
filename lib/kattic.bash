#!/usr/bin/env bash

demo () {
  do_postgres
  do_rabbitmq
  do_percona
  do_jupyter
  do_mongodb
  do_jenkins
  do_kafka
  do_redis
  do_minio
}

do_redis () {
  cd $KUBASH_DIR/submodules/openebs/k8s/demo/redis
  kubectl --kubeconfig=$KUBECONFIG apply -f \
   redis-statefulset.yml
}

do_postgres () {
  cd $KUBASH_DIR/submodules/openebs/k8s/demo/crunchy-postgres
  KUBECONFIG=$KUBECONFIG bash run.sh
}

do_rabbitmq () {
  cd $KUBASH_DIR/submodules/openebs/k8s/demo/rabbitmq
  KUBECONFIG=$KUBECONFIG bash run.sh
}

do_percona () {
  cd $KUBASH_DIR/submodules/openebs/k8s/demo/percona
  kubectl --kubeconfig=$KUBECONFIG apply -f \
   demo-percona-mysql-pvc.yaml
}

do_jupyter () {
  cd $KUBASH_DIR/submodules/openebs/k8s/demo/jupyter
  kubectl --kubeconfig=$KUBECONFIG apply -f \
   demo-jupyter-openebs.yaml
}

do_mongodb () {
  cd $KUBASH_DIR/submodules/openebs/k8s/demo/mongodb
  kubectl --kubeconfig=$KUBECONFIG apply -f \
   mongo-statefulset.yml
}

do_jenkins () {
  cd $KUBASH_DIR/submodules/openebs/k8s/demo/jenkins
  kubectl --kubeconfig=$KUBECONFIG apply -f \
   jenkins.yml
}

do_minio () {
  cd $KUBASH_DIR/submodules/openebs/k8s/demo/minio
  kubectl --kubeconfig=$KUBECONFIG apply -f \
   minio.yaml
}

do_kafka () {
  squawk 1 " do_kafka"
  KUBECONFIG=$KUBECONFIG \
  helm \
    repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator

  KUBECONFIG=$KUBECONFIG \
  helm install \
  --name my-kafka \
  incubator/kafka \
    --set persistence.storageClass=openebs-kafka
}

do_searchlight () {
  squawk 1 " do_searchlight"
  kubectl --kubeconfig=$KUBECONFIG apply -f \
    $KUBASH_DIR/templates/searchlight.yaml
}

do_dashboard () {
  squawk 1 " do_dashboard"
  kubectl --kubeconfig=$KUBECONFIG \
    apply -f \
    https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
}

do_tiller () {
  #w8_kubedns
  squawk 1 " do_tiller"
  #kubectl --kubeconfig=$KUBECONFIG create serviceaccount tiller --namespace kube-system
  kubectl --kubeconfig=$KUBECONFIG create -f $KUBASH_DIR/tiller/rbac-tiller-config.yaml
  sleep 5
  KUBECONFIG=$KUBECONFIG \
   helm init --service-account tiller
}

write_ansible_hosts () {
  write_ansible_kubespray_hosts
}

write_ansible_kubeadm2ha_hosts () {
  squawk 1 " Make a hosts file for kubeadm2ha ansible"
  # Make a fresh hosts file
  slurpy="$(grep -v '^#' $KUBASH_HOSTS_CSV)"
  if [[ -e "$KUBASH_ANSIBLE_HOSTS" ]]; then
    horizontal_rule
    rm $KUBASH_ANSIBLE_HOSTS
    touch $KUBASH_ANSIBLE_HOSTS
  else
    touch $KUBASH_ANSIBLE_HOSTS
  fi
  # Write all hosts to inventory for id
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    echo "$K8S_node ansible_ssh_host=$K8S_ip1 ansible_ssh_port=$K8S_sshPort ansible_user=$K8S_provisionerUser" >> $KUBASH_ANSIBLE_HOSTS
  done <<< "$slurpy"

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  echo '[primary-master]'  >> $KUBASH_ANSIBLE_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "primary_master" ]]; then
      echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
    fi
  done <<< "$slurpy"
  echo '' >> $KUBASH_ANSIBLE_HOSTS
  echo '[secondary-masters]'  >> $KUBASH_ANSIBLE_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "master" ]]; then
      echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
    fi
  done <<< "$slurpy"
  echo '' >> $KUBASH_ANSIBLE_HOSTS
  echo '[masters]'  >> $KUBASH_ANSIBLE_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "master" ]]; then
      echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
    elif [[ "$K8S_role" == "primary_master" ]]; then
      echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  echo '[etcd]'  >> $KUBASH_ANSIBLE_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" = "etcd" ]]; then
      echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
    elif [[ "$K8S_role" == "master" || "$K8S_role" == "primary_master" ]]; then
      if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
        echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
      fi
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  echo '[minions]'  >> $KUBASH_ANSIBLE_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "node" ]]; then
      echo "$K8S_node $openshift_labels" >> $KUBASH_ANSIBLE_HOSTS
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  echo '[nodes]'  >> $KUBASH_ANSIBLE_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "node" ]]; then
      echo "$K8S_node $openshift_labels" >> $KUBASH_ANSIBLE_HOSTS
    elif [[ "$K8S_role" == "master" || "$K8S_role" == "primary_master" ]]; then
      echo "$K8S_node $openshift_labels" >> $KUBASH_ANSIBLE_HOSTS
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  echo '[nginx]'  >> $KUBASH_ANSIBLE_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" = "ingress" ]]; then
      echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  echo '[nfs-server]'  >> $KUBASH_ANSIBLE_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" = "nfs-server" ]]; then
      echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  cat $KUBASH_DIR/templates/my-cluster.inventory.tail >> $KUBASH_ANSIBLE_HOSTS
}

write_ansible_openshift_hosts () {
  squawk 1 " Make a hosts file for openshift ansible"
  # Make a fresh hosts file
  slurpy="$(grep -v '^#' $KUBASH_HOSTS_CSV)"
  if [[ -e "$KUBASH_ANSIBLE_HOSTS" ]]; then
    horizontal_rule
    rm $KUBASH_ANSIBLE_HOSTS
    touch $KUBASH_ANSIBLE_HOSTS
  else
    touch $KUBASH_ANSIBLE_HOSTS
  fi
  # Write all hosts to inventory for id
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    echo "$K8S_node ansible_ssh_host=$K8S_ip1 ansible_ssh_port=$K8S_sshPort ansible_user=$K8S_provisionerUser" >> $KUBASH_ANSIBLE_HOSTS
  done <<< "$slurpy"

  echo '' >> $KUBASH_ANSIBLE_HOSTS
  echo '[OSEv3:children]' >> $KUBASH_ANSIBLE_HOSTS
  echo 'masters' >> $KUBASH_ANSIBLE_HOSTS
  echo 'nodes' >> $KUBASH_ANSIBLE_HOSTS
  echo 'etcd' >> $KUBASH_ANSIBLE_HOSTS

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  echo '[OSEv3:vars]
openshift_deployment_type=origin
deployment_type=origin
openshift_release=v3.7
openshift_release=v3.7
openshift_pkg_version=-3.7.0
debug_level=2
openshift_disable_check=disk_availability,memory_availability,docker_storage,docker_image_availability
openshift_master_default_subdomain=apps.cbqa.in
osm_default_node_selector="region=lab"' >> $KUBASH_ANSIBLE_HOSTS

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  echo '[masters]'  >> $KUBASH_ANSIBLE_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "master" ]]; then
      echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
    elif [[ "$K8S_role" == "primary_master" ]]; then
      echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  echo '[etcd]'  >> $KUBASH_ANSIBLE_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" = "etcd" ]]; then
      echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
    elif [[ "$K8S_role" == "master" || "$K8S_role" == "primary_master" ]]; then
      if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
        echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
      fi
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  openshift_labels="openshift_node_labels=\"{'region': '$OPENSHIFT_REGION', 'zone': '$OPENSHIFT_ZONE'}\" openshift_schedulable=true"
  echo '[nodes]'  >> $KUBASH_ANSIBLE_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "node" ]]; then
      echo "$K8S_node $openshift_labels" >> $KUBASH_ANSIBLE_HOSTS
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_ANSIBLE_HOSTS

  echo '[ingress]'  >> $KUBASH_ANSIBLE_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" = "ingress" ]]; then
      echo "$K8S_node" >> $KUBASH_ANSIBLE_HOSTS
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_ANSIBLE_HOSTS
}

write_ansible_kubespray_hosts () {
  squawk 1 " Make a hosts file for ansible"
  cp -av $KUBASH_DIR/submodules/kubespray/inventory/sample $KUBASH_CLUSTER_DIR/inventory
  # Make a fresh hosts file
  slurpy="$(grep -v '^#' $KUBASH_HOSTS_CSV)"
  if [[ -e "$KUBASH_KUBESPRAY_HOSTS" ]]; then
    horizontal_rule
    rm $KUBASH_KUBESPRAY_HOSTS
    touch $KUBASH_KUBESPRAY_HOSTS
  else
    touch $KUBASH_KUBESPRAY_HOSTS
  fi
  # Write all hosts to inventory for id
  set_csv_columns
  echo '[all]'  >> $KUBASH_KUBESPRAY_HOSTS
  while IFS="," read -r $csv_columns
  do
    echo "$K8S_node ip=$K8S_ip1 etcd_member_name=$K8S_node ansible_ssh_host=$K8S_ip1 ansible_ssh_port=$K8S_sshPort ansible_user=$K8S_provisionerUser" >> $KUBASH_KUBESPRAY_HOSTS
  done <<< "$slurpy"

  echo '' >> $KUBASH_KUBESPRAY_HOSTS

  echo '[kube-node]' >> $KUBASH_KUBESPRAY_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "node" ]]; then
      echo "$K8S_node" >> $KUBASH_KUBESPRAY_HOSTS
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_KUBESPRAY_HOSTS

  echo '[kube-node:vars]' >> $KUBASH_KUBESPRAY_HOSTS
  echo 'ansible_ssh_extra_args="-o StrictHostKeyChecking=no"' >> $KUBASH_KUBESPRAY_HOSTS

  echo '' >> $KUBASH_KUBESPRAY_HOSTS

  echo '[calico-rr]' >> $KUBASH_KUBESPRAY_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "master" ]]; then
      echo "$K8S_node" >> $KUBASH_KUBESPRAY_HOSTS
    elif [[ "$K8S_role" == "primary_master" ]]; then
      echo "$K8S_node" >> $KUBASH_KUBESPRAY_HOSTS
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_KUBESPRAY_HOSTS
  echo '[kube-master]' >> $KUBASH_KUBESPRAY_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "master" ]]; then
      echo "$K8S_node" >> $KUBASH_KUBESPRAY_HOSTS
    elif [[ "$K8S_role" == "primary_master" ]]; then
      echo "$K8S_node" >> $KUBASH_KUBESPRAY_HOSTS
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_KUBESPRAY_HOSTS

  echo '[kube-master:vars]' >> $KUBASH_KUBESPRAY_HOSTS
  echo 'ansible_ssh_extra_args="-o StrictHostKeyChecking=no"' >> $KUBASH_KUBESPRAY_HOSTS

  echo '' >> $KUBASH_KUBESPRAY_HOSTS

  echo '[etcd]'  >> $KUBASH_KUBESPRAY_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" = "etcd"  || "$K8S_role" == "primary_etcd" ]]; then
      echo "$K8S_node" >> $KUBASH_KUBESPRAY_HOSTS
    elif [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == "master" || "$K8S_role" == "primary_master" ]]; then
        echo "$K8S_node" >> $KUBASH_KUBESPRAY_HOSTS
      fi
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_KUBESPRAY_HOSTS

  echo '[vault]'  >> $KUBASH_KUBESPRAY_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" = "etcd"  || "$K8S_role" == "primary_etcd" ]]; then
      echo "$K8S_node" >> $KUBASH_KUBESPRAY_HOSTS
    elif [[ "$K8S_role" == "master" || "$K8S_role" == "primary_master" ]]; then
      if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
        echo "$K8S_node" >> $KUBASH_KUBESPRAY_HOSTS
      fi
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_KUBESPRAY_HOSTS

  echo '[ingress]'  >> $KUBASH_KUBESPRAY_HOSTS
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" = "ingress" ]]; then
      echo "$K8S_node" >> $KUBASH_KUBESPRAY_HOSTS
    fi
  done <<< "$slurpy"

  echo '' >> $KUBASH_KUBESPRAY_HOSTS

  echo '[k8s-cluster:children]' >> $KUBASH_KUBESPRAY_HOSTS
  echo 'kube-node' >> $KUBASH_KUBESPRAY_HOSTS
  echo 'kube-master' >> $KUBASH_KUBESPRAY_HOSTS
}

kubash_context () {
  KUBECONFIG=$KUBECONFIG \
  kubectl config set-context kubash \
  --user=kubernetes-admin \
  --cluster=$KUBASH_CLUSTER_NAME
  KUBECONFIG=$KUBECONFIG \
  kubectl config use-context kubash
}

removestalekeys () {
  squawk 1 " removestalekeys $@"
  node_ip=$1
  ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$node_ip"
}

w8_kubedns () {
  squawk 3 "wait on Kube-DNS to become available" -n
  sleep 1

  # while loop
  kubedns_countone=1
  # timeout for 15 minutes
  while [[ $kubedns_countone -lt 151 ]]
  do
    squawk 1 '.' -n
    RESULT=$(kubectl --kubeconfig=$KUBECONFIG get po --namespace kube-system |grep kube-dns|grep Running)
    if [[ "$RESULT" ]]; then
        sleep 3
        squawk 1 '.' -n
        squawk 3 "$RESULT"
        break
    fi
    ((++kubedns_countone))
    sleep 3
  done

  echo "Kube-DNS is now up and running"
  sleep 1
}

w8_kubectl () {
  squawk 3 "Wait on the K8S cluster to become available" -n
  squawk 3 "Errors on the first few tries are normal give it a few minutes to spin up" -n
  sleep 15
  # while loop
  countone_w8_kubectl=1
  countlimit_w8_kubectl=151
  # timeout for 15 minutes
  while [[ "$countone_w8_kubectl" -lt "$countlimit_w8_kubectl" ]]; do
    squawk 1 '.' -n
    if [[ "$VERBOSITY" -gt "11" ]] ; then
      squawk 105 "kubectl --kubeconfig=$KUBECONFIG get pods -n kube-system | grep kube-apiserver"
      kubectl --kubeconfig=$KUBECONFIG get pods -n kube-system | grep kube-apiserver
    fi
    result=$(kubectl --kubeconfig=$KUBECONFIG get pods -n kube-system 2>/dev/null | grep kube-apiserver |grep Running)
    squawk 3 "Result is $result"
    if [[ "$result" ]]; then
      squawk 5 "Result nailed $result"
      ((++countone_w8_kubectl))
      break
    fi
    ((++countone_w8_kubectl))
    squawk 209 "$countone_w8_kubectl"
    if [[ "$countone_w8_kubectl" -ge "$countlimit_w8_kubectl"  ]]; then
      croak 3  'Master is not coming up, investigate, breaking'
    fi
    sleep 5
  done
  squawk 3  "."
  squawk 1 "kubectl commands are now able to interact with the kubernetes cluster"
}

w8_node () {
  node_name=$1
  squawk 3 "Wait on the K8S node $node_name to become available" -n
  sleep 5
  # while loop
  countone_w8_node=1
  countlimit_w8_node=151
  # timeout for 15 minutes
  set +e
  while [[ "$countone_w8_node" -lt "$countlimit_w8_node" ]]; do
    squawk 1 '.' -n
    if [[ "$VERBOSITY" -gt "11" ]] ; then
      squawk 105  "kubectl --kubeconfig=$KUBECONFIG get node $node_name"
      kubectl --kubeconfig=$KUBECONFIG get node $node_name
    fi
    result=$(kubectl --kubeconfig=$KUBECONFIG get node $node_name | grep -v NotReady | grep Ready)
    squawk 133 "Result is $result"
    if [[ "$result" ]]; then
      squawk 5 "Result nailed $result"
      ((++countone_w8_node))
      break
    fi
    ((++countone_w8_node))
    squawk 209 "$countone_w8_node"
    sleep 3
  done
  set -e
  squawk 3  "."
  squawk 3  "kubectl commands are now able to interact with the kubernetes node"
}

remove_vagrant_user () {
  remove_vagrant_user_tmp_para=$(mktemp -d)
  squawk 2 ' Remove vagrant user from all hosts using ssh'
  touch $remove_vagrant_user_tmp_para/hopper
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    squawk 1 "$K8S_ip1"
    squawk 3 "$K8S_user"
    squawk 3 "$K8S_os"
    if [[ "$K8S_os" == 'coreos' ]]; then
      squawk 9 'coreos so skipping'
    else
      REMMY="userdel -fr vagrant"
      squawk 6 "ssh -n -p $K8S_sshPort $K8S_user@$K8S_ip1 \"$REMMY\""
      echo "ssh -n -p $K8S_sshPort $K8S_user@$K8S_ip1 \"$REMMY\""\
        >> $remove_vagrant_user_tmp_para/hopper
    fi
  done < $KUBASH_HOSTS_CSV

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $remove_vagrant_user_tmp_para/hopper
  fi

  set +e #some of the new builds have been erroring out as vagrant has been removed already, softening
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $remove_vagrant_user_tmp_para/hopper
  else
    bash $remove_vagrant_user_tmp_para/hopper
  fi
  set -e # End softening

  rm -Rf $remove_vagrant_user_tmp_para
}

hostname_in_parallel () {
  hostname_tmp_para=$(mktemp -d --suffix='.para.tmp')
  squawk 2 ' Hostnaming all hosts using ssh'
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    my_HOST=$K8S_node
    my_IP=$K8S_ip1
    my_PORT=$K8S_sshPort
    my_USER=$K8S_provisionerUser
    command2run="ssh -n -p $my_PORT $my_USER@$my_IP '$PSEUDO hostname $my_HOST && echo $my_HOST | $PSEUDO tee /etc/hostname && echo \"127.0.1.1 $my_HOST.$my_DOMAIN $my_HOST  \" | $PSEUDO tee -a /etc/hosts'"
    squawk 5 "$command2run"
    echo "$command2run" \
      >> $hostname_tmp_para/hopper
  done <<< "$kubash_hosts_csv_slurped"

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $hostname_tmp_para/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $hostname_tmp_para/hopper
  else
    bash $hostname_tmp_para/hopper
  fi
  rm -Rf $hostname_tmp_para
}

ping_in_parallel () {
  ping_tmp_para=$(mktemp -d --suffix='.para.tmp')
  squawk 2 ' Pinging all hosts using ssh'
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    squawk 103 "ping $K8S_user@$K8S_ip1"
    #MY_ECHO="this_hostname=\"$(hostname| tr -d '\n')\" this_date=\"$(date| tr -d '\n')\" echo '$K8S_ip1 $K8S_provisionerUser pong $this_hostname $this_date'" 
    #MY_ECHO="echo -e -n "PONG\t";hostname|tr -d  '\n';echo -e -n "\t";date +%s|tr -d '\n';echo -e -n '$K8S_ip1';echo -e -n "\t";uname -a" 
    #MY_PING=$(ping -c1 $K8S_ip1|tail -n1|cut -f4 -d' '|cut -d'/' -f1|tr -d '\n')
    MY_ECHO="date +%s|tr -d '\n';echo -n ' $K8S_ip1';echo -n ' PONG ';hostname|tr -d  '\n';echo -n ' ';echo -e -n ' ';uname -a"
    squawk 5 "ssh -n -p $K8S_sshPort $K8S_provisionerUser@$K8S_ip1 \"$MY_ECHO\""
    echo "ssh -n -p $K8S_sshPort $K8S_provisionerUser@$K8S_ip1 \"$MY_ECHO\""\
        >> $ping_tmp_para/hopper
  done < $KUBASH_HOSTS_CSV

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $ping_tmp_para/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $ping_tmp_para/hopper
  else
    bash $ping_tmp_para/hopper
  fi
  rm -Rf $ping_tmp_para
}

ping () {
  squawk 2 ' Pinging all hosts using ssh'
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    squawk 1 "$K8S_ip1"
    squawk 3 "$K8S_user"
    if [[ "$VERBOSITY" -gt 10 ]]; then
      ssh -n -p $K8S_sshPort $K8S_user@$K8S_ip1 'echo pong'
      squawk 3 "$K8S_provisionerUser"
      ssh -n -p $K8S_sshPort $K8S_provisionerUser@$K8S_ip1 'echo pong'
    else
      ssh -n -p $K8S_sshPort $K8S_user@$K8S_ip1 'touch /tmp/sshpingtest-kubash'
      ssh -n -p $K8S_sshPort $K8S_provisionerUser@$K8S_ip1 'touch /tmp/sshpingtest-kubash'
    fi
  done < $KUBASH_HOSTS_CSV
}

ansible-ping () {
  squawk 1 ' Pinging all hosts using Ansible'
  ansible -i $KUBASH_ANSIBLE_HOSTS -m ping all
}

chkdir () {
  if [[ ! -w $1 ]] ; then
    sudo mkdir -p $1
    sudo chown $USER. $1
  fi
  if [[ ! -w $1 ]] ; then
    echo "Cannot write to $1, please check your permissions"
    exit 2
  fi
}

inst_kubedb_helm () {
  helm repo add appscode https://charts.appscode.com/stable/
  helm repo update
  helm install appscode/kubedb --name kubedb-operator --version 0.10.0 --namespace kube-system
  $KUBASH_DIR/w8s/generic.w8 kubedb-operator kube-system
  helm install appscode/kubedb-catalog --name kubedb-catalog --version 0.10.0 --namespace kube-system
}

dotfiles_install () {
  squawk 1 ' Adjusting dotfiles'
  touch $HOME/.zshrc
  touch $HOME/.bashrc
  # make a bin dir in $HOME and add it to path
  chkdir $KUBASH_BIN
  LINE_TO_ADD="$(printf "export PATH=%s:\$PATH" $KUBASH_BIN)"
  TARGET_FILE_FOR_ADD=$HOME/.bashrc
  check_if_line_exists || add_line_to
  TARGET_FILE_FOR_ADD=$HOME/.zshrc
  check_if_line_exists || add_line_to

  LINE_TO_ADD="export GOPATH=$GOPATH"
  TARGET_FILE_FOR_ADD=$HOME/.bashrc
  check_if_line_exists || add_line_to
  TARGET_FILE_FOR_ADD=$HOME/.zshrc
  check_if_line_exists || add_line_to
}

do_grab () {
  squawk 1 " do_grab"
  do_grab_master_count=0
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "primary_master" ]]; then
      if [[ "$do_grab_master_count" -lt "1" ]]; then
        master_grab_kube_config $K8S_node $K8S_ip1 $K8S_provisionerUser $K8S_sshPort
      fi
      ((++do_grab_master_count))
    fi
  done < $KUBASH_HOSTS_CSV
}

check_coreos () {
  squawk 1 " check_coreos"
  do_coreos_init_count=0
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_os" == "coreos" ]]; then
      if [[ "$do_coreos_init_count" -lt "1" ]]; then
        do_coreos_initialization
  break
      fi
      ((++do_coreos_init_count))
    fi
  done < $KUBASH_HOSTS_CSV
}

master_join () {
  squawk 1 " master_join $@"
  my_node_name=$1
  my_node_ip=$2
  my_node_user=$3
  my_node_port=$4


  if [[ "$DO_MASTER_JOIN" == "true" ]] ; then
    #finish_pki_for_masters $my_node_user $my_node_ip $my_node_name $my_node_port
    ssh -n -p $my_node_port $my_node_user@$my_node_ip "$PSUEDO hostname;$PSUEDO  uname -a"
    run_join=$(cat $KUBASH_CLUSTER_DIR/join.sh)
    squawk 1 " run join $run_join"
    ssh -n -p $my_node_port $my_node_user@$my_node_ip "$PSEUDO $run_join"
    w8_node $my_node_name
    rolero $my_node_name master
  fi
}

master_init_join () {
  squawk 1 " master_init_join $@"
  my_master_name=$1
  my_master_ip=$2
  my_master_user=$3
  my_master_port=$4
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi

  #finish_pki_for_masters $my_master_user $my_master_ip $my_master_name $my_master_port

  rm -f $KUBASH_CLUSTER_DIR/ingress.ip1
  rm -f $KUBASH_CLUSTER_DIR/ingress.ip2
  rm -f $KUBASH_CLUSTER_DIR/ingress.ip3
  rm -f $KUBASH_CLUSTER_DIR/primary_master.ip1
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "ingress" ]]; then
      echo "$K8S_ip1" >> $KUBASH_CLUSTER_DIR/ingress.ip1
      echo "$K8S_ip2" >> $KUBASH_CLUSTER_DIR/ingress.ip2
      echo "$K8S_ip3" >> $KUBASH_CLUSTER_DIR/ingress.ip3
    elif [[ "$K8S_role" == "primary_master" ]]; then
      echo "$K8S_ip1" >> $KUBASH_CLUSTER_DIR/primary_master.ip1
    fi
  done <<< "$kubash_hosts_csv_slurped"
  if [[ -e  "$KUBASH_CLUSTER_DIR/ingress.ip2" ]]; then
    K8S_load_balancer_ip=$(head -n1 $KUBASH_CLUSTER_DIR/ingress.ip2)
  elif [[ -e  "$KUBASH_CLUSTER_DIR/ingress.ip3" ]]; then
    K8S_load_balancer_ip=$(head -n1 $KUBASH_CLUSTER_DIR/ingress.ip3)
  elif [[ -e  "$KUBASH_CLUSTER_DIR/ingress.ip1" ]]; then
    K8S_load_balancer_ip=$(head -n1 $KUBASH_CLUSTER_DIR/ingress.ip1)
  elif [[ -e  "$KUBASH_CLUSTER_DIR/primary_master.ip1" ]]; then
    K8S_load_balancer_ip=$(head -n1 $KUBASH_CLUSTER_DIR/primary_master.ip1)
  else
    croak 3  'no load balancer ip'
  fi

  if [[ "DO_KEEPALIVED" == 'true' ]]; then
    #keepalived
    setup_keepalived_tmp=$(mktemp -d)

    MASTER_VIP=$my_master_ip \
    envsubst < $KUBASH_DIR/templates/check_apiserver.sh \
    > $setup_keepalived_tmp/check_apiserver.sh
    copy_in_parallel_to_role master $setup_keepalived_tmp/check_apiserver.sh "/tmp/"
    command2run='sudo  mv /tmp/check_apiserver.sh /etc/keepalived/'
    do_command_in_parallel_on_role "master" "$command2run"

    MASTER_OR_BACKUP=BACKUP \
    PRIORITY=100 \
    INTERFACE_NET=$INTERFACE_NET \ 
    MASTER_VIP=$my_master_ip \
    envsubst < $KUBASH_DIR/templates/keepalived.conf
    > $setup_keepalived_tmp/keepalived.conf
    copy_in_parallel_to_role master $setup_keepalived_tmp/keepalived.conf "/tmp/"
    command2run='sudo  mv /tmp/keepalived.conf /etc/keepalived/'
    do_command_in_parallel_on_role "master" "$command2run"
    # Then let's overwrite that on our primary master
    MASTER_OR_BACKUP=MASTER \
    PRIORITY=101 \
    INTERFACE_NET=$INTERFACE_NET \ 
    MASTER_VIP=$my_master_ip \
    envsubst < $KUBASH_DIR/templates/keepalived.conf
    > $setup_keepalived_tmp/keepalived.conf
    rsync $KUBASH_RSYNC_OPTS "ssh -p $my_master_port" $setup_keepalived_tmp/keepalived.conf $my_master_user@$my_master_ip:/tmp/keepalived.conf
    command2run='sudo  mv /tmp/keepalived.conf /etc/keepalived/'
    ssh -n -p $my_master_port $my_master_user@$my_master_ip "$command2run"

    rm -f $setup_keepalived_tmp/keepalived.conf $setup_keepalived_tmp/check_apiserver.sh
    rmdir $setup_keepalived_tmp
  fi

  squawk 3 " master_init_join $my_master_name $my_master_ip $my_master_user $my_master_port"
  if [[ "$DO_MASTER_JOIN" == "true" ]] ; then
    ssh -n -p $my_master_port $my_master_user@$my_master_ip "$PSEUDO hostname;$PSEUDO  uname -a"
    my_grep='kubeadm join --token'
    squawk 3 'master_init_join kubeadm init'
    command2run='sudo systemctl restart kubelet'
    do_command_in_parallel_on_role "primary_master" "$command2run"
    do_command_in_parallel_on_role "master" "$command2run"
    #ssh -n -p $my_master_port $my_master_user@$my_master_ip "$command2run"
    command2run='sudo systemctl stop kubelet'
    #ssh -n -p $my_master_port $my_master_user@$my_master_ip "$command2run"
    do_command_in_parallel_on_role "primary_master" "$command2run"
    do_command_in_parallel_on_role "master" "$command2run"
    command2run='sudo netstat -ntpl'
    do_command_in_parallel_on_role "master" "$command2run"
    ssh -n -p $my_master_port $my_master_user@$my_master_ip "$command2run"
    if [[ -e "$KUBASH_CLUSTER_DIR/endpoints.line" ]]; then
      #kubeadmin_config_tmp=$(mktemp)
      #KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
      #my_master_ip=$my_master_ip \
      #load_balancer_ip=$K8S_load_balancer_ip \
      #my_KUBE_CIDR=$my_KUBE_CIDR \
      #ENDPOINTS_LINES=$( cat $KUBASH_CLUSTER_DIR/endpoints.line) \
      #envsubst  < $KUBASH_DIR/templates/kubeadm-config-1.12.yaml \
        #> $kubeadmin_config_tmp
      #squawk 19 "rsync $KUBASH_RSYNC_OPTS 'ssh -p $my_master_port' $kubeadmin_config_tmp  $my_master_user@$my_master_ip:/tmp/config.yaml"
      #rsync $KUBASH_RSYNC_OPTS "ssh -p $my_master_port" $kubeadmin_config_tmp  $my_master_user@$my_master_ip:/tmp/config.yaml
      #squawk 6 "kubedmin_config_tmp =\n $(cat $kubeadmin_config_tmp)" -e
      #rm $kubeadmin_config_tmp
      my_KUBE_INIT="PATH=$K8S_SU_PATH $PSEUDO kubeadm init $KUBEADMIN_IGNORE_PREFLIGHT_CHECKS --config=/etc/kubernetes/kubeadmcfg.yaml"
      squawk 5 "$my_KUBE_INIT"
      run_join=$(ssh -n $my_master_user@$my_master_ip "$my_KUBE_INIT" | tee $TMP/rawresults.k8s | grep -- "$my_grep")
      if [[ -z "$run_join" ]]; then
        horizontal_rule
        croak 3  'kubeadm init failed!'
      fi
      #command2run='sudo  rm -f /tmp/config.yaml'
      #ssh -n -p $my_master_port $my_master_user@$my_master_ip "$command2run"
    else
      #my_KUBE_INIT="PATH=$K8S_SU_PATH $PSEUDO kubeadm init $KUBEADMIN_IGNORE_PREFLIGHT_CHECKS --pod-network-cidr=$my_KUBE_CIDR"
      #my_KUBE_INIT="PATH=$K8S_SU_PATH $PSEUDO kubeadm init $KUBEADMIN_IGNORE_PREFLIGHT_CHECKS --config=/etc/kubernetes/kubeadmcfg-external.yaml"
      my_KUBE_INIT="PATH=$K8S_SU_PATH $PSEUDO kubeadm init $KUBEADMIN_IGNORE_PREFLIGHT_CHECKS --config=/etc/kubernetes/kubeadmcfg.yaml"
      squawk 5 "$my_KUBE_INIT"
      run_join=$(ssh -n $my_master_user@$my_master_ip "$my_KUBE_INIT" | tee $TMP/rawresults.k8s | grep -- "$my_grep")
      if [[ -z "$run_join" ]]; then
        horizontal_rule
        croak 3  'kubeadm init failed!'
      fi
    fi
    squawk 9 "$(cat $TMP/rawresults.k8s)"
    echo $run_join > $KUBASH_CLUSTER_DIR/join.sh
    if [[ "$KUBASH_OIDC_AUTH" == 'true' ]]; then
      command2run='sudo sed -i "/- kube-apiserver/a\    - --oidc-issuer-url=https://accounts.google.com\n    - --oidc-username-claim=email\n    - --oidc-client-id=" /etc/kubernetes/manifests/kube-apiserver.yaml'
      ssh -n -p $my_master_port $my_master_user@$my_master_ip "$command2run"
    fi
    master_grab_kube_config $my_master_name $my_master_ip $my_master_user $my_master_port
    sudo_command $my_master_port $my_master_user $my_master_ip "$command2run"
    w8_kubectl
    rsync $KUBASH_RSYNC_OPTS "ssh -p $my_master_port" $KUBASH_DIR/scripts/grabkubepki $my_master_user@$my_master_ip:/tmp/grabkubepki
    command2run="bash /tmp/grabkubepki"
    sudo_command $this_port $this_user $this_host "$command2run"
    rsync $KUBASH_RSYNC_OPTS "ssh -p $my_master_port" $my_master_user@$my_master_ip:/tmp/kube-pki.tgz $KUBASH_CLUSTER_DIR/
    squawk 5 'and copy it to master and etcd hosts'
    copy_in_parallel_to_role "master" "$KUBASH_CLUSTER_DIR/kube-pki.tgz" "/tmp/"
    if [ "$VERBOSITY" -gt 5 ]; then
      command2run='cd /; tar ztvf /tmp/kube-pki.tgz'
      do_command_in_parallel_on_role "master"        "$command2run"
    fi
    command2run='cd /; tar zxf /tmp/kube-pki.tgz'
    do_command_in_parallel_on_role "master"        "$command2run"
    command2run='rm /tmp/kube-pki.tgz'
    do_command_in_parallel_on_role "master"        "$command2run"
    do_net
  fi
}

master_grab_kube_config () {
  my_master_name=$1
  my_master_ip=$2
  my_master_user=$3
  my_master_port=$4
  squawk 1 ' refresh-kube-config'
  squawk 3 " master_grab_kube_config $my_master_name $my_master_ip $my_master_user $my_master_port"
  squawk 5 "mkdir -p ~/.kube && sudo cp -av /etc/kubernetes/admin.conf ~/.kube/config && sudo chown -R $my_master_user. ~/.kube"
  ssh -n -p $my_master_port $my_master_user@$my_master_ip "mkdir -p ~/.kube && sudo cp -av /etc/kubernetes/admin.conf ~/.kube/config && sudo chown -R $my_master_user. ~/.kube"

  chkdir $HOME/.kube
  squawk 3 ' grab config'
  rm -f $KUBASH_CLUSTER_CONFIG
  ssh -n -p $my_master_port $my_master_user@$my_master_ip 'cat .kube/config' > $KUBASH_CLUSTER_CONFIG
  sed -i "s/^  name: kubernetes$/  name: $KUBASH_CLUSTER_NAME/" $KUBASH_CLUSTER_CONFIG
  sed -i "s/^    cluster: kubernetes$/    cluster: $KUBASH_CLUSTER_NAME/" $KUBASH_CLUSTER_CONFIG

  sudo chmod 600 $KUBASH_CLUSTER_CONFIG
  sudo chown -R $USER. $KUBASH_CLUSTER_CONFIG
}

node_join () {
  my_node_name=$1
  my_node_ip=$2
  my_node_user=$3
  my_node_port=$4
  squawk 1 " node_join $my_node_name $my_node_ip $my_node_user $my_node_port"
  if [[ "$DO_NODE_JOIN" == "true" ]] ; then
    result=$(ssh -n -p $my_node_port $my_node_user@$my_node_ip "$PSEUDO hostname;$PSEUDO uname -a")
    squawk 3 "hostname and uname is $result"
    squawk 3 "Kubeadmin join"
    run_join=$(cat $KUBASH_CLUSTER_DIR/join.sh)
    #result=$(ssh -n -p $my_node_port $my_node_user@$my_node_ip "$PSEUDO $run_join --ignore-preflight-errors=IsPrivilegedUser")
    result=$(ssh -n -p $my_node_port $my_node_user@$my_node_ip "$PSEUDO $run_join --ignore-preflight-errors=IsPrivilegedUser")
    squawk 3 "run_join result is $result"
    w8_node $my_node_name
    rolero $my_node_name node
  fi
}

checks () {
  squawk 5 " checks"
  check_cmd git
  check_cmd nc
  check_cmd ssh
  check_cmd rsync
  check_cmd ansible
  check_cmd curl
  check_cmd nmap
  check_cmd uname
  check_cmd envsubst
  check_cmd ct
  check_cmd jinja2
  check_cmd yaml2json
  check_cmd jq
  check_cmd rlwrap
  check_cmd expr
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    check_cmd parallel
  fi
  check_cmd 'grep'
  check_cmd 'sed'
}

read_csv () {
  squawk 1 " read_csv"
  read_master_count=0

  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    squawk 5 "$K8S_node $K8S_user $K8S_ip1 $K8S_sshPort $K8S_role $K8S_provisionerUser $K8S_provisionerHost $K8S_provisionerUser $K8S_provisionerPort"
    if [[ "$K8S_role" == "master" ]]; then
      if [[ "$read_master_count" -lt "1" ]]; then
        echo "master_init_join $K8S_node $K8S_ip1 $K8S_provisionerUser $K8S_sshPort"
      else
        echo "master_join $K8S_node $K8S_ip1 $K8S_provisionerUser $K8S_sshPort"
      fi
      ((++read_master_count))
    fi
  done < $KUBASH_HOSTS_CSV

  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "node" || "$K8S_role" == "ingress" ]]; then
      echo "node_join $K8S_node $K8S_ip1 $K8S_provisionerUser $K8S_sshPort"
    fi
  done < $KUBASH_HOSTS_CSV
}

check_csv () {
  squawk 4 " check_csv"
  if [[ ! -e $KUBASH_HOSTS_CSV ]]; then
    horizontal_rule
    echo "$KUBASH_HOSTS_CSV file not found!"
    croak 3  "You must provision a cluster first, and specify a valid cluster with the --clustername option and place your hosts.csv file in its directory!"
  fi
}

grant () {
  user_role=$3
  grant_tmp=$(mktemp)
  USERNAME_OF_ADMIN=$1 \
  EMAIL_ADDRESS_OF_ADMIN=$2 \
  envsubst < $KUBASH_DIR/templates/$user_role-role \
    > $grant_tmp
  kubectl --kubeconfig=$KUBECONFIG apply -f $grant_tmp
  rm $grant_tmp
}

grant_users () {
  grant_users_tmp_para=$(mktemp -d --suffix='.para.tmp' 2>/dev/null || mktemp -d -t '.para.tmp')
  touch $grant_users_tmp_para/hopper
  slurpy="$(grep -v '^#' $KUBASH_USERS_CSV)"
  # user_csv_columns="user_email user_role"
  set_csv_columns
  while IFS="," read -r $user_csv_columns
  do
    squawk 9 "user_name=$user_name user_email=$user_email user_role=$user_role"
    echo "kubash -n $KUBASH_CLUSTER_NAME grant $user_name $user_email $user_role" >> $grant_users_tmp_para/hopper
  done <<< "$slurpy"

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $grant_users_tmp_para/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $grant_users_tmp_para/hopper
  else
    bash $grant_users_tmp_para/hopper
  fi
  rm -Rf $grant_users_tmp_para
}

finish_pki_for_masters () {
  squawk 5 "finish_pki_for_masters $@"
  if [[ $# -ne 4 ]]; then
    kubash_interactive
    echo 'Arguments does not equal 4!'
    croak 3  "Arguments: $@"
  fi
  this_user=$1
  this_host=$2
  this_name=$3
  this_port=$4
  command2run='mkdir -p /etc/kubernetes/pki/etcd'
  sudo_command $this_port $this_user $this_host "$command2run"
  squawk 5 'cp the etcd pki files'
  command2run="cp -v /etc/etcd/pki/ca.pem /etc/etcd/pki/client.pem /etc/etcd/pki/client-key.pem /etc/kubernetes/pki/etcd/"
  sudo_command $this_port $this_user $this_host "$command2run"
}

get_major_minor_kube_version () {
  this_user=$1
  this_host=$2
  this_name=$3
  this_port=$4
  #command2run="kubeadm version 2>/dev/null |sed \'s/^.*Major:\"\([1234567890]*\)\", Minor:\"\([1234567890]*\)\", GitVersion:.*$/\1,\2/\'"
  command2run="kubeadm version 2>/dev/null"
  TEST_KUBEADM_VER=$(sudo_command $this_port $this_user $this_host "$command2run" \
    |grep -v -P '^#'\
    |sed 's/^.*Major:\"\([1234567890]*\)\", Minor:\"\([1234567890]*\)\", GitVersion:.*$/\1,\2/' \
  )
  KUBE_MAJOR_VER=$(echo $TEST_KUBEADM_VER|cut -f1 -d,)
  KUBE_MINOR_VER=$(echo $TEST_KUBEADM_VER|cut -f2 -d,)
  squawk 185 "kube major: $KUBE_MAJOR_VER kube minor: $KUBE_MINOR_VER"
}

finish_etcd () {
  this_user=$1
  this_host=$2
  this_name=$3
  this_port=$4
  get_major_minor_kube_version $this_user $this_host $this_name $this_port
  if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
    squawk 20 'Major Version 1'
    if [[ $KUBE_MINOR_VER -lt 12 ]]; then
      finish_etcd_direct_download $this_user $this_host $this_name $this_port
    else
      croak 3  'stubbed not working yet'
      #finish_etcd_kubelet_download $this_user $this_host $this_name $this_port
    fi
  elif [[ $MAJOR_VER -eq 0 ]]; then
    croak 3 'Major Version 0 unsupported'
  else
    croak 3 'Major Version Unknown'
  fi
}

finish_etcd_kubelet_download () {
  squawk 5 'finish_etcd_kubelet_download'
  this_user=$1
  this_host=$2
  this_name=$3
  this_port=$4
}

finish_etcd_direct_download () {
  squawk 5 'finish_etcd_direct_download'
  this_user=$1
  this_host=$2
  this_name=$3
  this_port=$4

  command2run="cd /etc/etcd/pki; cfssl print-defaults csr > config.json"
  sudo_command $this_port $this_user $this_host "$command2run"
  command2run="sed -i '0,/CN/{s/example\.net/'$this_name'/}' /etc/etcd/pki/config.json"
  sudo_command $this_port $this_user $this_host "$command2run"
  command2run="sed -i 's/www\.example\.net/'$this_host'/' /etc/etcd/pki/config.json"
  sudo_command $this_port $this_user $this_host "$command2run"
  command2run="sed -i 's/example\.net/'$this_name'/' /etc/etcd/pki/config.json"
  sudo_command $this_port $this_user $this_host "$command2run"
  command2run="cd /etc/etcd/pki; cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server config.json | cfssljson -bare server"
  sudo_command $this_port $this_user $this_host "$command2run"
  command2run="cd /etc/etcd/pki; cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer config.json | cfssljson -bare peer"
  sudo_command $this_port $this_user $this_host "$command2run"
  command2run='chown -R etcd:etcd /etc/etcd/pki'
  sudo_command $this_port $this_user $this_host "$command2run"

  if [[ -e $KUBASH_DIR/tmp/etcd-${ETCD_VERSION}-linux-amd64.tar.gz ]]; then
    squawk 9 'Etcd binary already downloaded'
  else
    cd $KUBASH_DIR/tmp
    wget -c https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
  fi
  command2run='id -u etcd &>/dev/null || useradd etcd'
  sudo_command $this_port $this_user $this_host "$command2run"
  etcd_extract_tmp=$(mktemp -d)
  sudo tar --strip-components=1 -C $etcd_extract_tmp -xzf $KUBASH_DIR/tmp/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
  rsync $KUBASH_RSYNC_OPTS "ssh -p $this_port" $etcd_extract_tmp/etcd $this_user@$this_host:/tmp/
  rsync $KUBASH_RSYNC_OPTS "ssh -p $this_port" $etcd_extract_tmp/etcdctl $this_user@$this_host:/tmp/
  $PSEUDO rm -Rf $etcd_extract_tmp
  command2run='sudo mv /tmp/etcd /usr/local/bin/'
  do_command $this_port $this_user $this_host "$command2run"
  command2run='sudo mv /tmp/etcdctl /usr/local/bin/'
  do_command $this_port $this_user $this_host "$command2run"
  etctmp=$(mktemp)
  KUBASH_CLUSTER_NAME=$KUBASH_CLUSTER_NAME \
  PEER_NAME=$this_name \
  PRIVATE_IP=$this_host \
  ETCD_INITCLUSER_LINE="$(cat $KUBASH_CLUSTER_DIR/etcd.line)" \
  envsubst < $KUBASH_DIR/templates/etcd.conf.yml \
  > $etctmp
  rsync $KUBASH_RSYNC_OPTS "ssh -p $this_port" $etctmp  $this_user@$this_host:/tmp/etcd.conf.yml
  command2run="mv /tmp/etcd.conf.yml /etc/etcd/etcd.conf.yml"
  sudo_command $this_port $this_user $this_host "$command2run"

  rsync $KUBASH_RSYNC_OPTS "ssh -p $this_port" $KUBASH_DIR/templates/etcd.service  $this_user@$this_host:/tmp/etcd.service
  command2run='mv /tmp/etcd.service /lib/systemd/system/etcd.service'
  sudo_command $this_port $this_user $this_host "$command2run"

  rm $etctmp
  command2run='mkdir -p /etc/etcd; chown -R etcd.etcd /etc/etcd'
  sudo_command $this_port $this_user $this_host "$command2run"
  command2run='mkdir -p /var/lib/etcd; chown -R etcd.etcd /var/lib/etcd'
  sudo_command $this_port $this_user $this_host "$command2run"
  command2run='systemctl daemon-reload'
  sudo_command $this_port $this_user $this_host "$command2run"
}

start_etcd () {

  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  # Run kubeadm init on master0
  start_etcd_tmp_para=$(mktemp -d --suffix='.para.tmp' 2>/dev/null)
  touch $start_etcd_tmp_para/hopper
  squawk 3 " start_etcd"

  countzero=0
  touch $start_etcd_tmp_para/endpoints.line
  #echo 'etcd:' >> $start_etcd_tmp_para/endpoints.line
  echo ' external:' >> $start_etcd_tmp_para/endpoints.line
  echo '  endpoints:' >> $start_etcd_tmp_para/endpoints.line
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "etcd" || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
      if [[ "$countzero" -lt "3" ]]; then
  command2run='systemctl start etcd'
  squawk 5 "ssh -n -p $K8S_sshPort $K8S_provisionerUser@$K8S_ip1 'sudo bash -c \"$command2run\"'"
  echo "ssh -n -p $K8S_sshPort $K8S_provisionerUser@$K8S_ip1 'sudo bash -c \"$command2run\"'" >> $start_etcd_tmp_para/hopper
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $start_etcd_tmp_para/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $start_etcd_tmp_para/hopper
  else
    bash $start_etcd_tmp_para/hopper
  fi
  rm -Rf $start_etcd_tmp_para
}

kubeadm_reset () {
  squawk 3 "Kubeadmin reset"
  command2run="PATH=$K8S_SU_PATH yes y|kubeadm reset"
  # hack if debugging to skip this step
  set +e
  do_command_in_parallel "$command2run"
  #set -e
}

prep_init_etcd () {
  prep_init_etcd_user=$1
  prep_init_etcd_host=$2
  prep_init_etcd_name=$3
  prep_init_etcd_port=$4

  get_major_minor_kube_version $prep_init_etcd_user $prep_init_etcd_host $prep_init_etcd_name $prep_init_etcd_port
  if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
    squawk 175 'Kube Major Version 1 for prep init etcd'
    if [[ $KUBE_MINOR_VER -lt 12 ]]; then
      #croak 3  "$KUBE_MAJOR_VER.$KUBE_MINOR_VER less than 12 broken atm prep_init_etcd_kubelet_download $prep_init_etcd_user $prep_init_etcd_host $prep_init_etcd_name $prep_init_etcd_port"
      squawk 175 "$KUBE_MAJOR_VER.$KUBE_MINOR_VER Kube Minor Version less than 12 for prep init etcd"
      prep_init_etcd_classic $prep_init_etcd_user $prep_init_etcd_host $prep_init_etcd_name $prep_init_etcd_port
    else
      squawk 175 "$KUBE_MAJOR_VER.$KUBE_MINOR_VER for prep init etcd"
      squawk 55 "prep_init_etcd_kubelet_download $prep_init_etcd_user $prep_init_etcd_host $prep_init_etcd_name $prep_init_etcd_port"
      prep_init_etcd_kubelet_download $prep_init_etcd_user $prep_init_etcd_host $prep_init_etcd_name $prep_init_etcd_port
      squawk 83 'End pre_init_etcd'
    fi
  elif [[ $MAJOR_VER -eq 0 ]]; then
    croak 3 'Major Version 0 unsupported'
  else
    croak 3 'Major Version Unknown'
  fi
}

prep_init_etcd_kubelet_download  () {
  squawk 5 prep_init_etcd_kubelet_download
  prep_init_etcd_kubelet_download_tmp=$(mktemp -d)
  prep_init_etcd_kubelet_download_user=$1
  prep_init_etcd_kubelet_download_host=$2
  prep_init_etcd_kubelet_download_name=$3
  prep_init_etcd_kubelet_download_port=$4

  squawk 55 "prep_20-etcd-service-manager $prep_init_etcd_kubelet_download_user $prep_init_etcd_kubelet_download_host $prep_init_etcd_kubelet_download_name $prep_init_etcd_kubelet_download_port"
  prep_20-etcd-service-manager $prep_init_etcd_kubelet_download_user $prep_init_etcd_kubelet_download_host $prep_init_etcd_kubelet_download_name $prep_init_etcd_kubelet_download_port
  squawk 76 'end etcd prep_20'

  sleep 3

  command2run='netstat -ntpl'
  sudo_command $prep_init_etcd_kubelet_download_port $prep_init_etcd_kubelet_download_user $prep_init_etcd_kubelet_download_host "$command2run"
  command2run='kubeadm  alpha phase certs etcd-ca'
  sudo_command $prep_init_etcd_kubelet_download_port $prep_init_etcd_kubelet_download_user $prep_init_etcd_kubelet_download_host "$command2run"
  command2run='ls -lh /etc/kubernetes/pki/etcd/ca.crt'
  #sudo_command $prep_init_etcd_kubelet_download_port $prep_init_etcd_kubelet_download_user $prep_init_etcd_kubelet_download_host "$command2run"
  command2run='ls -lh /etc/kubernetes/pki/etcd/ca.key'
  #sudo_command $prep_init_etcd_kubelet_download_port $prep_init_etcd_kubelet_download_user $prep_init_etcd_kubelet_download_host "$command2run"

  squawk 55 "prep_etcd_gen_certs $prep_init_etcd_kubelet_download_port $prep_init_etcd_kubelet_download_user $prep_init_etcd_kubelet_download_host $prep_init_etcd_kubelet_download_port $prep_init_etcd_kubelet_download_user $prep_init_etcd_kubelet_download_host"
  prep_etcd_gen_certs $prep_init_etcd_kubelet_download_port $prep_init_etcd_kubelet_download_user $prep_init_etcd_kubelet_download_host $prep_init_etcd_kubelet_download_port $prep_init_etcd_kubelet_download_user $prep_init_etcd_kubelet_download_host
}

prep_20-etcd-service-manager () {
  if [ $# -ne 4 ]; then
    # Print usage
    echo 'Error! wrong number of arguments'
    echo 'usage:'
    croak 3  "$0 user host name port"
  fi
  squawk 5 prep_init_etcd_kubelet_download
  prep_20_etcd_service_manager_tmp=$(mktemp -d)
  prep_20_etcd_service_manager_user=$1
  prep_20_etcd_service_manager_host=$2
  prep_20_etcd_service_manager_name=$3
  prep_20_etcd_service_manager_port=$4

  prep_20_etcd_service_manager_host=$2 \
  envsubst < \
    $KUBASH_DIR/templates/20-etcd-service-manager.conf \
    > $prep_20_etcd_service_manager_tmp/20-etcd-service-manager.conf
  squawk 55 "rsync -zave ssh -p $prep_20_etcd_service_manager_port $prep_20_etcd_service_manager_tmp/20-etcd-service-manager.conf $prep_20_etcd_service_manager_user@$prep_20_etcd_service_manager_host:/etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf"
  rsync -zave "ssh -p $prep_20_etcd_service_manager_port" $prep_20_etcd_service_manager_tmp/20-etcd-service-manager.conf $prep_20_etcd_service_manager_user@$prep_20_etcd_service_manager_host:/etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
  rm $prep_20_etcd_service_manager_tmp/20-etcd-service-manager.conf
  rmdir $prep_20_etcd_service_manager_tmp
  command2run='systemctl daemon-reload && systemctl restart kubelet'
  squawk 55 "sudo_command $prep_20_etcd_service_manager_port $prep_20_etcd_service_manager_user $prep_20_etcd_service_manager_host $command2run"
  sudo_command $prep_20_etcd_service_manager_port $prep_20_etcd_service_manager_user $prep_20_etcd_service_manager_host "$command2run"
  squawk 99 'End prep_20-etcd-service-manager'
}

prep_etcd_gen_certs () {
  prepetcdgencerts_port=$1
  prepetcdgencerts_user=$2
  prepetcdgencerts_host=$3
  prepetcdgencerts_primary_etcd_master_port=$4
  prepetcdgencerts_primary_etcd_master_user=$5
  prepetcdgencerts_primary_etcd_master=$6
  squawk 55 "prep_etcd_gen_certs port $prepetcdgencerts_port user $prepetcdgencerts_user host $prepetcdgencerts_host on master $prepetcdgencerts_primary_etcd_master_user '@' $prepetcdgencerts_primary_etcd_master : $prepetcdgencerts_primary_etcd_master_port"
  command2run="find /tmp/${prepetcdgencerts_host} -name ca.key -type f -delete -print \
    && find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete -print \
    && kubeadm alpha phase certs etcd-server --config=/tmp/${prepetcdgencerts_host}/kubeadmcfg.yaml \
    && kubeadm alpha phase certs etcd-peer --config=/tmp/${prepetcdgencerts_host}/kubeadmcfg.yaml \
    && kubeadm alpha phase certs etcd-healthcheck-client --config=/tmp/${prepetcdgencerts_host}/kubeadmcfg.yaml \
    && kubeadm alpha phase certs apiserver-etcd-client --config=/tmp/${prepetcdgencerts_host}/kubeadmcfg.yaml \
    && cp -R /etc/kubernetes/pki /tmp/${prepetcdgencerts_host}/"
  sudo_command $prepetcdgencerts_primary_etcd_master_port  $prepetcdgencerts_primary_etcd_master_user  $prepetcdgencerts_primary_etcd_master "$command2run"
  squawk 86 'cleanup non-reusable certificates'
  command2run="find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete -print"
  sudo_command $prepetcdgencerts_primary_etcd_master_port  $prepetcdgencerts_primary_etcd_master_user  $prepetcdgencerts_primary_etcd_master "$command2run"
  if [[ "$prepetcdgencerts_host" == "$prepetcdgencerts_primary_etcd_master" ]]; then
    command2run="rsync -av /tmp/${prepetcdgencerts_host}/* /etc/kubernetes/"
    squawk 25 "$command2run"
    sudo_command $prepetcdgencerts_primary_etcd_master_port  $prepetcdgencerts_primary_etcd_master_user  $prepetcdgencerts_primary_etcd_master "$command2run"
    command2run="chown -R root:root /etc/kubernetes/pki"
    sudo_command $prepetcdgencerts_port $prepetcdgencerts_user $prepetcdgencerts_host "$command2run"
  else
    squawk 25 "$prepetcdgencerts_host !=  $prepetcdgencerts_primary_etcd_master"
    command2run="rsync -ave \"ssh -p $prepetcdgencerts_port\" /tmp/${prepetcdgencerts_host}/pki ${prepetcdgencerts_user}@${prepetcdgencerts_host}:/etc/kubernetes/"
    squawk 25 "$command2run"
    sudo_command $prepetcdgencerts_primary_etcd_master_port  $prepetcdgencerts_primary_etcd_master_user  $prepetcdgencerts_primary_etcd_master "$command2run"
    command2run="chown -R root:root /etc/kubernetes/pki"
    sudo_command $prepetcdgencerts_port $prepetcdgencerts_user $prepetcdgencerts_host "$command2run"
  fi
  squawk 86 "clean up certs that should not be copied off prepetcdgencerts host"
  command2run="find /tmp/${prepetcdgencerts_host} -name ca.key -type f -delete -print"
  sudo_command $prepetcdgencerts_primary_etcd_master_port  $prepetcdgencerts_primary_etcd_master_user  $prepetcdgencerts_primary_etcd_master "$command2run"
}

finalize_etcd_gen_certs () {
  finalize_etcdgencerts_port=$1
  finalize_etcdgencerts_user=$2
  finalize_etcdgencerts_host=$3
  squawk 55 "finalize_etcd_gen_certs port $finalize_etcdgencerts_port user $finalize_etcdgencerts_user host $finalize_etcdgencerts_host"
  command2run="cp -R  /tmp/${finalize_etcdgencerts_host}/kubeadmcfg.yaml /etc/kubernetes/ \
    && cp -R  /tmp/${finalize_etcdgencerts_host}/pki /etc/kubernetes/ \
    && chown -R root:root /etc/kubernetes/pki"
  sudo_command $finalize_etcdgencerts_port $finalize_etcdgencerts_user $finalize_etcdgencerts_host "$command2run"
}

prep_init_etcd_classic () {
  this_user=$1
  this_host=$2
  this_name=$3
  this_port=$4

  init_etcd_tmp=$(mktemp -d)
  mkdir $init_etcd_tmp/pki
  cp $KUBASH_DIR/templates/ca-config.json $init_etcd_tmp/pki/ca-config.json
  cp $KUBASH_DIR/templates/client.json $init_etcd_tmp/pki/client.json
  jinja2 $KUBASH_DIR/templates/ca-csr.json $KUBASH_CLUSTER_DIR/ca-data.yaml --format=yaml > $init_etcd_tmp/pki/ca-csr.json
  command2run='mkdir -p /etc/etcd'
  squawk 5 "command2run $command2run"
  sudo_command $this_port $this_user $this_host "$command2run"
  squawk 15 "rsync $KUBASH_RSYNC_OPTS 'ssh -p $this_port' $init_etcd_tmp/pki $this_user@$this_host:/tmp/"
  rsync $KUBASH_RSYNC_OPTS "ssh -p $this_port" $init_etcd_tmp/pki $this_user@$this_host:/tmp/
  command2run='ls -lh /tmp/pki'
  #sudo_command $this_port $this_user $this_host "$command2run"
  command2run='rm -Rf /etc/etcd/pki'
  sudo_command $this_port $this_user $this_host "$command2run"
  command2run='mv /tmp/pki /etc/etcd/pki'
  sudo_command $this_port $this_user $this_host "$command2run"
  rm -Rf $init_etcd_tmp

  command2run="chown $this_user /etc/etcd/pki"
  sudo_command $this_port $this_user $this_host "$command2run"
  rsync $KUBASH_RSYNC_OPTS "ssh -p $this_port" $KUBASH_DIR/templates/ca-config.json $this_user@$this_host:/tmp/ca-config.json
  command2run='mv /tmp/ca-config.json /etc/etcd/pki/ca-config.json'
  sudo_command $this_port $this_user $this_host "$command2run"

  # crictl
  if [[ $DO_CRICTL = 'true' ]]; then
    real_path_crictl=$(realpath ${KUBASH_BIN}/crictl)
    copy_in_parallel_to_all "$real_path_crictl" "/tmp/crictl"
    command2run='mv /tmp/crictl /usr/local/bin/crictl'
    do_command_in_parallel "$command2run"
  fi

  copy_in_parallel_to_all "${KUBASH_BIN}/cfssljson" "/tmp/cfssljson"
  command2run='mv /tmp/cfssljson /usr/local/bin/cfssljson'
  sudo_command $this_port $this_user $this_host "$command2run"
  do_command_in_parallel "$command2run"

  copy_in_parallel_to_all "${KUBASH_BIN}/cfssl" "/tmp/cfssl"
  command2run='mv /tmp/cfssl /usr/local/bin/cfssl'
  sudo_command $this_port $this_user $this_host "$command2run"
  do_command_in_parallel "$command2run"

  # Hack, delete after rebuild
  #command2run="echo 'PATH=/usr/local/bin:$PATH' >> /root/.bash_profile"
  #sudo_command $this_port $this_user $this_host "$command2run"
  #do_command_in_parallel_on_role "etcd"          "$command2run"
  #if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
  #  do_command_in_parallel_on_role "master"        "$command2run"
  #fi

  # add etcd user if it doesn't exist
  command2run='id -u etcd &>/dev/null || useradd etcd'
  sudo_command $this_port $this_user $this_host "$command2run"
  do_command_in_parallel_on_role "etcd"          "$command2run"
  if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
    do_command_in_parallel_on_role "master"        "$command2run"
  fi

  command2run='cd /etc/etcd/pki; cfssl gencert -initca ca-csr.json | cfssljson -bare ca -'
  sudo_command $this_port $this_user $this_host "$command2run"

  command2run='cd /etc/etcd/pki; cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client'
  sudo_command $this_port $this_user $this_host "$command2run"

  rsync $KUBASH_RSYNC_OPTS "ssh -p $this_port" $KUBASH_DIR/scripts/grabpki $this_user@$this_host:/tmp/grabpki
  command2run="bash /tmp/grabpki"
  sudo_command $this_port $this_user $this_host "$command2run"
  squawk 5 'pull etcd-pki.tgz from primary master'
  rsync $KUBASH_RSYNC_OPTS "ssh -p $this_port" $this_user@$this_host:/tmp/etcd-pki.tgz $KUBASH_CLUSTER_DIR/
  squawk 5 'and copy it to master and etcd hosts'
  copy_in_parallel_to_role "etcd" "$KUBASH_CLUSTER_DIR/etcd-pki.tgz" "/tmp/"
  copy_in_parallel_to_role "master" "$KUBASH_CLUSTER_DIR/etcd-pki.tgz" "/tmp/"
  command2run='cd /; tar zxf /tmp/etcd-pki.tgz'
  do_command_in_parallel_on_role "master"        "$command2run"
  do_command_in_parallel_on_role "etcd"          "$command2run"
  command2run='rm /tmp/etcd-pki.tgz'
  do_command_in_parallel_on_role "master"        "$command2run"
  do_command_in_parallel_on_role "etcd"          "$command2run"
  finish_etcd $this_user $this_host $this_name $this_port
}

prep_etcd () {
  squawk 5 'prep_etcd'
  this_user=$1
  this_host=$2
  this_name=$3
  this_port=$4

  get_major_minor_kube_version $this_user $this_host $this_name $this_port
  if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
    squawk 175 'Kube Major Version 1 for prep etcd'
    if [[ $KUBE_MINOR_VER -lt 12 ]]; then
      squawk 75 'Kube Minor Version less than 12 for prep etcd'
      finish_etcd $this_user $this_host $this_name $this_port
    else
      squawk 75 'Kube Major Version greater than or equal to 12 for prep etcd'
      if [[ -e $KUBASH_CLUSTER_DIR/kube_primary_etcd ]]; then
        kube_primary=$(cat $KUBASH_CLUSTER_DIR/kube_primary_etcd)
        kube_primary_port=$(cat $KUBASH_CLUSTER_DIR/kube_primary_etcd_port)
        kube_primary_user=$(cat $KUBASH_CLUSTER_DIR/kube_primary_etcd_user)
      elif [[ -e $KUBASH_CLUSTER_DIR/kube_primary ]]; then
        kube_primary=$(cat $KUBASH_CLUSTER_DIR/kube_primary)
        kube_primary_port=$(cat $KUBASH_CLUSTER_DIR/kube_primary_port)
        kube_primary_user=$(cat $KUBASH_CLUSTER_DIR/kube_primary_user)
      else
        croak 3  'no master found'
      fi
      prep_etcd_gen_certs $this_port $this_user $this_host $kube_primary_port $kube_primary_user $kube_primary
      #prep_etcd_gen_certs $this_port $this_user $this_host $this_port $kube_primary_user $kube_primary
    fi
  elif [[ $MAJOR_VER -eq 0 ]]; then
    croak 3 'Major Version 0 unsupported'
  else
    croak 3 'Major Version Unknown'
  fi
}

set_ip_files () {
  # First find the primary etcd master
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "primary_master"  ]]; then
      if [[ "$countprimarymaster" -eq "0" ]]; then
        # save these values for clusterwide usage
        echo $K8S_ip1 > $KUBASH_CLUSTER_DIR/kube_primary
        echo $K8S_sshPort > $KUBASH_CLUSTER_DIR/kube_primary_port
        echo $K8S_provisionerUser > $KUBASH_CLUSTER_DIR/kube_primary_user
      else
        croak 3  'there should only be one primary master'
      fi
      ((++countprimarymaster))
    elif [[ "$K8S_role" == "primary_etcd"  ]]; then
      if [[ "$countprimaryetcd" -eq "0" ]]; then
        # save these values for clusterwide usage
        echo $K8S_ip1 > $KUBASH_CLUSTER_DIR/kube_primary_etcd
        echo $K8S_sshPort > $KUBASH_CLUSTER_DIR/kube_primary_etcd_port
        echo $K8S_provisionerUser > $KUBASH_CLUSTER_DIR/kube_primary_etcd_user
      else
        croak 3  'there should only be one primary etcd'
      fi
      ((++countprimaryetcd))
    elif [[ "$K8S_role" == "master"  ]]; then
      echo $K8S_ip1 > $KUBASH_CLUSTER_DIR/kube_master${countmaster}
      echo $K8S_sshPort > $KUBASH_CLUSTER_DIR/kube_master${countmaster}_port
      echo $K8S_provisionerUser > $KUBASH_CLUSTER_DIR/kube_master${countmaster}_user
      ((++countmaster))
    elif [[ "$K8S_role" == "etcd"  ]]; then
      echo $K8S_ip1 > $KUBASH_CLUSTER_DIR/kube_etcd${countetcd}
      echo $K8S_sshPort > $KUBASH_CLUSTER_DIR/kube_etcd${countetcd}_port
      echo $K8S_provisionerUser > $KUBASH_CLUSTER_DIR/kube_etcd${countetcd}_user
      ((++countetcd))
    fi
  done <<< "$kubash_hosts_csv_slurped"
}

write_kubeadmcfg_yaml () {
  squawk 3 " write kubeadmcfg.yaml files"
  do_etcd_tmp_para=$(mktemp -d --suffix='.para.tmp' 2>/dev/null || mktemp -d -t '.para.tmp')
  touch $do_etcd_tmp_para/hopper
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi

  countprimarymaster=0
  countprimaryetcd=0
  countmaster=1
  countetcd=1
  set_csv_columns
  set_ip_files
  my_master_ip=$( cat $KUBASH_CLUSTER_DIR/kube_primary)
  my_master_user=$( cat $KUBASH_CLUSTER_DIR/kube_primary_user)
  my_master_port=$( cat $KUBASH_CLUSTER_DIR/kube_primary_port)
  # create  config files

  # create tmpdirs for configs
  while IFS="," read -r $csv_columns
  do
        if [[ -e $KUBASH_CLUSTER_DIR/kube_primary_etcd ]]; then
          my_primary_etcd_port=$(cat $KUBASH_CLUSTER_DIR/kube_primary_etcd_port)
          my_primary_etcd_user=$(cat  $KUBASH_CLUSTER_DIR/kube_primary_etcd_user)
          my_primary_etcd_ip=$(cat $KUBASH_CLUSTER_DIR/kube_primary_etcd)
          command2run="mkdir -p /tmp/${K8S_ip1}"
          sudo_command $my_primary_etcd_port $my_primary_etcd_user $my_primary_etcd_ip "$command2run"
        elif [[ -e $KUBASH_CLUSTER_DIR/kube_primary ]]; then
          command2run="mkdir -p /tmp/${K8S_ip1}"
          sudo_command $my_master_port $my_master_user $my_master_ip "$command2run"
        else
          croak 3  'no master found'
        fi
  done <<< "$kubash_hosts_csv_slurped"
  countzero=0
  touch $do_etcd_tmp_para/endpoints.line
  touch $do_etcd_tmp_para/etcd.line
  #echo 'etcd:' > $do_etcd_tmp_para/etcd.line

  # servercertSANS
  echo "${TAB_2}serverCertSANS:" >> $do_etcd_tmp_para/servercertsans.line
  echo "${TAB_2}- '127.0.0.1'" >> $do_etcd_tmp_para/servercertsans.line
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
      echo "${TAB_2}- '$K8S_ip1'" >> $do_etcd_tmp_para/servercertsans.line
    fi
  done <<< "$kubash_hosts_csv_slurped"
  # peercertSANS
  echo "${TAB_2}peerCertSANS:" >> $do_etcd_tmp_para/peercertsans.line
  echo "${TAB_2}- '127.0.0.1'" >> $do_etcd_tmp_para/peercertsans.line
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
      echo "${TAB_2}- '$K8S_ip1'" >> $do_etcd_tmp_para/peercertsans.line
    fi
  done <<< "$kubash_hosts_csv_slurped"

  echo "${TAB_2}extraArgs:" > $do_etcd_tmp_para/extraargs.head
  echo -n "${TAB_3}initial-cluster: " > $do_etcd_tmp_para/initial-cluster.head
  count_etcd=0
  countetcdnodes=0
  while IFS="," read -r $csv_columns
  do
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        if [[ $countetcdnodes -gt 0 ]]; then
          printf ',' >> $do_etcd_tmp_para/initial-cluster.line
        fi
        printf "${K8S_node}=https://${K8S_ip1}:2380" >> $do_etcd_tmp_para/initial-cluster.line
        ((++countetcdnodes))
      fi
    else
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
        if [[ $countetcdnodes -gt 0 ]]; then
          printf ',' >> $do_etcd_tmp_para/initial-cluster.line
        fi
        printf "${K8S_node}=https://${K8S_ip1}:2380" >> $do_etcd_tmp_para/initial-cluster.line
        ((++countetcdnodes))
      fi
    fi
    ((++count_etcd))
  done <<< "$kubash_hosts_csv_slurped"
  printf " \n" >> $do_etcd_tmp_para/initial-cluster.line
  echo "${TAB_1}external:" >> $do_etcd_tmp_para/external-endpoints.line
  echo "${TAB_2}endpoints:" >> $do_etcd_tmp_para/external-endpoints.line
  while IFS="," read -r $csv_columns
  do
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        echo "${TAB_2}- https://${K8S_ip1}:2379" >> $do_etcd_tmp_para/external-endpoints.line
      fi
    else
      if [[ "$K8S_role" == 'etcd' ]]; then
        echo "${TAB_2}- https://${K8S_ip1}:2379" >> $do_etcd_tmp_para/external-endpoints.line
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"
  echo "${TAB_2}caFile: /etc/kubernetes/pki/etcd/ca.crt"                 >> $do_etcd_tmp_para/external-endpoints.line
  echo "${TAB_2}certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt" >> $do_etcd_tmp_para/external-endpoints.line
  echo "${TAB_2}keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key"  >> $do_etcd_tmp_para/external-endpoints.line

  while IFS="," read -r $csv_columns
  do
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        echo "${TAB_1}local:" > $do_etcd_tmp_para/${K8S_node}etcd.line
        #echo "${TAB_2}serverCertSANS:" >> $do_etcd_tmp_para/${K8S_node}etcd.line
        #echo "${TAB_2}- '$K8S_ip1'"    >> $do_etcd_tmp_para/${K8S_node}etcd.line
        #echo "${TAB_2}peerCertSANS:"   >> $do_etcd_tmp_para/${K8S_node}etcd.line
        #echo "${TAB_2}- '$K8S_ip1'"    >> $do_etcd_tmp_para/${K8S_node}etcd.line
        #printf " \n" >> $do_etcd_tmp_para/${K8S_node}extraargs.line
        echo "${TAB_3}initial-cluster-state: new" >> $do_etcd_tmp_para/${K8S_node}extraargs.line
        echo "${TAB_3}name: $K8S_node"            >> $do_etcd_tmp_para/${K8S_node}extraargs.line
        echo "${TAB_3}listen-peer-urls: https://${K8S_ip1}:2380"    >> $do_etcd_tmp_para/${K8S_node}extraargs.line
      fi
    else
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
        echo "${TAB_1}local:" > $do_etcd_tmp_para/${K8S_node}etcd.line
        #echo "${TAB_2}serverCertSANS:" >> $do_etcd_tmp_para/${K8S_node}etcd.line
        #echo "${TAB_2}- '$K8S_ip1'"    >> $do_etcd_tmp_para/${K8S_node}etcd.line
        #echo "${TAB_2}peerCertSANS:"   >> $do_etcd_tmp_para/${K8S_node}etcd.line
        #echo "${TAB_2}- '$K8S_ip1'"    >> $do_etcd_tmp_para/${K8S_node}etcd.line
        #printf " \n" >> $do_etcd_tmp_para/${K8S_node}extraargs.line
        echo "${TAB_3}initial-cluster-state: new" >> $do_etcd_tmp_para/${K8S_node}extraargs.line
        echo "${TAB_3}name: $K8S_node"       >> $do_etcd_tmp_para/${K8S_node}extraargs.line
        echo "${TAB_3}listen-peer-urls: https://${K8S_ip1}:2380"    >> $do_etcd_tmp_para/${K8S_node}extraargs.line
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"

  while IFS="," read -r $csv_columns
  do
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        echo -n "${TAB_3}listen-client-urls: " >> $do_etcd_tmp_para/${K8S_node}extraargs.line
        echo "https://${K8S_ip1}:2379"     >> $do_etcd_tmp_para/${K8S_node}extraargs.line
      fi
    else
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
        echo -n "${TAB_3}listen-client-urls: " >> $do_etcd_tmp_para/${K8S_node}extraargs.line
        echo "https://${K8S_ip1}:2379"     >> $do_etcd_tmp_para/${K8S_node}extraargs.line
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"

  while IFS="," read -r $csv_columns
  do
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        echo -n "${TAB_3}advertise-client-urls: " >> $do_etcd_tmp_para/${K8S_node}extraargs.line
        echo  "https://${K8S_ip1}:2379" >> $do_etcd_tmp_para/${K8S_node}extraargs.line
      fi
    else
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
        echo -n "${TAB_3}advertise-client-urls: " >> $do_etcd_tmp_para/${K8S_node}extraargs.line
        echo  "https://${K8S_ip1}:2379" >> $do_etcd_tmp_para/${K8S_node}extraargs.line
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"

  while IFS="," read -r $csv_columns
  do
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        echo -n "${TAB_3}initial-advertise-peer-urls: " >> $do_etcd_tmp_para/${K8S_node}extraargs.line
        echo  "https://${K8S_ip1}:2380"             >> $do_etcd_tmp_para/${K8S_node}extraargs.line
      fi
    else
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
        echo -n "${TAB_3}initial-advertise-peer-urls: " >> $do_etcd_tmp_para/${K8S_node}extraargs.line
        echo  "https://${K8S_ip1}:2380"             >> $do_etcd_tmp_para/${K8S_node}extraargs.line
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"

  # deprecated these are no longer used in the current kubeadm
  #echo '  caFile: /etc/kubernetes/pki/etcd/ca.pem' >> $do_etcd_tmp_para/etcdcerts.line
  #echo '  certFile: /etc/kubernetes/pki/etcd/client.pem' >> $do_etcd_tmp_para/etcdcerts.line
  #echo '  keyFile: /etc/kubernetes/pki/etcd/client-key.pem' >> $do_etcd_tmp_para/etcdcerts.line

  squawk 19 "check number of etcd nodes"
  if [[ "$countetcdnodes" -lt "3" ]]; then
    croak 3  "not enough etcd nodes, [$countetcdnodes]"
  else
    if [[ "$((countetcdnodes%2))" -eq 0 ]]; then
      croak 3  "number of etcd nodes, [$countetcdnodes] is even which is not supported"
    fi
  fi

  if [[ -e $KUBASH_CLUSTER_DIR/kube_primary_etcd ]]; then
    my_master_ip=$(cat $KUBASH_CLUSTER_DIR/kube_primary_etcd)
    my_master_user=$(cat  $KUBASH_CLUSTER_DIR/kube_primary_etcd_user)
    my_master_port=$(cat $KUBASH_CLUSTER_DIR/kube_primary_etcd_port)
  elif [[ -e $KUBASH_CLUSTER_DIR/kube_primary ]]; then
    my_master_ip=$( cat $KUBASH_CLUSTER_DIR/kube_primary)
    my_master_user=$( cat $KUBASH_CLUSTER_DIR/kube_primary_user)
    my_master_port=$( cat $KUBASH_CLUSTER_DIR/kube_primary_port)
  else
    croak 3  'no master found'
  fi
  # create  config files
  while IFS="," read -r $csv_columns
  do
    get_major_minor_kube_version $K8S_user $K8S_ip1  $K8S_node $K8S_sshPort
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' || "$K8S_role" == 'primary_etcd' ]]; then
        cat $do_etcd_tmp_para/endpoints.line \
        $do_etcd_tmp_para/${K8S_node}etcd.line \
        $do_etcd_tmp_para/servercertsans.line \
        $do_etcd_tmp_para/peercertsans.line \
        $do_etcd_tmp_para/extraargs.head \
        $do_etcd_tmp_para/initial-cluster.head \
        $do_etcd_tmp_para/initial-cluster.line \
        $do_etcd_tmp_para/${K8S_node}extraargs.line \
        > $KUBASH_CLUSTER_DIR/${K8S_node}endpoints.line

        if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
          squawk 20 'Major Version 1'
          if [[ $KUBE_MINOR_VER -lt 9 ]]; then
            croak 3  "$KUBE_MINOR_VER is too old may not ever be supported"
          elif [[ $KUBE_MINOR_VER -eq 11 ]]; then
            kubeadmin_config_tmp=$(mktemp)
            my_master_ip=$( cat $KUBASH_CLUSTER_DIR/kube_primary) \
            KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
            load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
            my_KUBE_CIDR=$my_KUBE_CIDR \
            ENDPOINTS_LINES=$( cat $KUBASH_CLUSTER_DIR/${K8S_node}endpoints.line ) \
            envsubst  < $KUBASH_DIR/templates/kubeadm-config-1.11.yaml \
              > $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml
          elif [[ $KUBE_MINOR_VER -eq 12 ]]; then
            kubeadmin_config_tmp=$(mktemp)
            my_master_ip=$( cat $KUBASH_CLUSTER_DIR/kube_primary) \
            KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
            load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
            my_KUBE_CIDR=$my_KUBE_CIDR \
            ENDPOINTS_LINES=$( cat $KUBASH_CLUSTER_DIR/${K8S_node}endpoints.line ) \
            envsubst  < $KUBASH_DIR/templates/kubeadm-config-1.12.yaml \
              > $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml
          else
            squawk 10 "$KUBE_MAJOR_VER.$KUBE_MINOR_VER supported"
            kubeadmin_config_tmp=$(mktemp)
            my_master_ip=$my_master_ip \
            KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
            load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
            my_KUBE_CIDR=$my_KUBE_CIDR \
            ENDPOINTS_LINES=$( cat $KUBASH_CLUSTER_DIR/${K8S_node}endpoints.line ) \
            envsubst  < $KUBASH_DIR/templates/kubeadm-config-${KUBE_MAJOR_VER}.${KUBE_MINOR_VER}.yaml \
              > $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml
          fi
        elif [[ $MAJOR_VER -eq 0 ]]; then
          croak 3 'Major Version 0 unsupported'
        else
          croak 3 'Major Version Unknown'
        fi

        # now for the external
        cat $do_etcd_tmp_para/endpoints.line \
        $do_etcd_tmp_para/external-endpoints.line \
        > $do_etcd_tmp_para/${K8S_node}endpoints.line

        if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
          squawk 20 'Major Version 1'
          if [[ $KUBE_MINOR_VER -lt 9 ]]; then
            croak 3  "$KUBE_MAJOR_VER.$KUBE_MINOR_VER is too old may not ever be supported"
          elif [[ $KUBE_MINOR_VER -eq 11 ]]; then
            kubeadmin_config_tmp=$(mktemp)
            my_master_ip=$( cat $KUBASH_CLUSTER_DIR/kube_primary) \
            KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
            load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
            my_KUBE_CIDR=$my_KUBE_CIDR \
            ENDPOINTS_LINES=$( cat $do_etcd_tmp_para/${K8S_node}endpoints.line) \
            envsubst  < $KUBASH_DIR/templates/kubeadm-config-external-1.11.yaml \
              > $do_etcd_tmp_para/${K8S_node}-external-kubeadmcfg.yaml
          elif [[ $KUBE_MINOR_VER -eq 12 ]]; then
            kubeadmin_config_tmp=$(mktemp)
            my_master_ip=$( cat $KUBASH_CLUSTER_DIR/kube_primary) \
            KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
            load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
            my_KUBE_CIDR=$my_KUBE_CIDR \
            ENDPOINTS_LINES=$( cat $do_etcd_tmp_para/${K8S_node}endpoints.line) \
            envsubst  < $KUBASH_DIR/templates/kubeadm-config-external-1.12.yaml \
              > $do_etcd_tmp_para/${K8S_node}-external-kubeadmcfg.yaml
          else
            squawk 10 "$KUBE_MAJOR_VER.$KUBE_MINOR_VER supported"
            kubeadmin_config_tmp=$(mktemp)
            my_master_ip=$my_master_ip \
            KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
            load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
            my_KUBE_CIDR=$my_KUBE_CIDR \
            ENDPOINTS_LINES=$( cat $KUBASH_CLUSTER_DIR/endpoints.line) \
            envsubst  < $KUBASH_DIR/templates/kubeadm-config-external-${KUBE_MAJOR_VER}.${KUBE_MINOR_VER}.yaml \
              > $do_etcd_tmp_para/${K8S_node}-external-kubeadmcfg.yaml
          fi
        elif [[ $MAJOR_VER -eq 0 ]]; then
          croak 3 'Major Version 0 unsupported'
        else
          croak 3 'Major Version Unknown'
        fi

        #squawk 25 "scp -P $K8S_sshPort $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml $K8S_SU_USER@$K8S_ip1:/tmp/kubeadmcfg.yaml"
        #scp -P $K8S_sshPort $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml $K8S_SU_USER@$K8S_ip1:/tmp/kubeadmcfg.yaml
        command2run="mkdir -p /tmp/${K8S_ip1}"
        sudo_command $my_master_port $my_master_user $my_master_ip "$command2run"
        squawk 25 "scp -P $my_master_port $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml $my_master_user@$my_master_ip:/tmp/${K8S_ip1}/kubeadmcfg.yaml"
        scp -P $my_master_port $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml $my_master_user@$my_master_ip:/tmp/${K8S_ip1}/kubeadmcfg.yaml
        scp -P $my_master_port $do_etcd_tmp_para/${K8S_node}-external-kubeadmcfg.yaml $my_master_user@$my_master_ip:/tmp/${K8S_ip1}/kubeadmcfg-external.yaml
        #csv_columns="K8S_node K8S_role K8S_cpuCount K8S_Memory K8S_sshPort K8S_network1 K8S_mac1 K8S_ip1 K8S_routingprefix1 K8S_subnetmask1 K8S_broadcast1 K8S_gateway1 K8S_provisionerHost K8S_provisionerUser K8S_provisionerPort K8S_provisionerBasePath K8S_os K8S_virt K8S_network2 K8S_mac2 K8S_ip2 K8S_routingprefix2 K8S_subnetmask2 K8S_broadcast2 K8S_gateway2 K8S_network3 K8S_mac3 K8S_ip3 K8S_routingprefix3 K8S_subnetmask3 K8S_broadcast3 K8S_gateway3"
        squawk 25 "scp -P $K8S_sshPort $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml $K8S_user@${K8S_ip1}:/etc/kubernetes/kubeadmcfg.yaml"
        scp -P $K8S_sshPort $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml $K8S_user@${K8S_ip1}:/etc/kubernetes/kubeadmcfg.yaml
        scp -P $K8S_sshPort $do_etcd_tmp_para/${K8S_node}-external-kubeadmcfg.yaml $K8S_user@${K8S_ip1}:/etc/kubernetes/kubeadmcfg-external.yaml
        squawk 73 'etcd prep_20'
        prep_20-etcd-service-manager $K8S_user ${K8S_ip1} ${K8S_node} $K8S_sshPort
        squawk 78 'end etcd prep_20'
      fi
    else
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
        cat $do_etcd_tmp_para/endpoints.line \
        $do_etcd_tmp_para/${K8S_node}etcd.line \
        $do_etcd_tmp_para/servercertsans.line \
        $do_etcd_tmp_para/peercertsans.line \
        $do_etcd_tmp_para/extraargs.head \
        $do_etcd_tmp_para/initial-cluster.head \
        $do_etcd_tmp_para/initial-cluster.line \
        $do_etcd_tmp_para/${K8S_node}extraargs.line \
        > $KUBASH_CLUSTER_DIR/${K8S_node}endpoints.line

        if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
          squawk 20 'Major Version 1'
          if [[ $KUBE_MINOR_VER -lt 9 ]]; then
            croak 3  "$KUBE_MINOR_VER is too old may not ever be supported"
          elif [[ $KUBE_MINOR_VER -eq 11 ]]; then
            kubeadmin_config_tmp=$(mktemp)
            my_master_ip=$( cat $KUBASH_CLUSTER_DIR/kube_primary) \
            KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
            load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
            my_KUBE_CIDR=$my_KUBE_CIDR \
            ENDPOINTS_LINES=$( cat $KUBASH_CLUSTER_DIR/${K8S_node}endpoints.line ) \
            envsubst  < $KUBASH_DIR/templates/kubeadm-config-1.11.yaml \
              > $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml
          elif [[ $KUBE_MINOR_VER -eq 12 ]]; then
            kubeadmin_config_tmp=$(mktemp)
            my_master_ip=$( cat $KUBASH_CLUSTER_DIR/kube_primary) \
            KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
            load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
            my_KUBE_CIDR=$my_KUBE_CIDR \
            ENDPOINTS_LINES=$( cat $KUBASH_CLUSTER_DIR/${K8S_node}endpoints.line ) \
            envsubst  < $KUBASH_DIR/templates/kubeadm-config-1.12.yaml \
              > $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml
          else
            squawk 10 "$KUBE_MAJOR_VER.$KUBE_MINOR_VER supported"
            kubeadmin_config_tmp=$(mktemp)
            my_master_ip=$my_master_ip \
            KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
            load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
            my_KUBE_CIDR=$my_KUBE_CIDR \
            ENDPOINTS_LINES=$( cat $KUBASH_CLUSTER_DIR/${K8S_node}endpoints.line ) \
            envsubst  < $KUBASH_DIR/templates/kubeadm-config-${KUBE_MAJOR_VER}.${KUBE_MINOR_VER}.yaml \
              > $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml
          fi
        elif [[ $MAJOR_VER -eq 0 ]]; then
          croak 3 'Major Version 0 unsupported'
        else
          croak 3 'Major Version Unknown'
        fi

        command2run="mkdir -p /tmp/${K8S_ip1}"
        sudo_command $my_master_port $my_master_user $my_master_ip "$command2run"
        squawk 25 "scp -P $my_master_port $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml $my_master_user@$my_master_ip:/tmp/${K8S_ip1}/kubeadmcfg.yaml"
        scp -P $my_master_port $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml $my_master_user@$my_master_ip:/tmp/${K8S_ip1}/kubeadmcfg.yaml
        squawk 25 "scp -P $K8S_sshPort $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml $K8S_user@${K8S_ip1}:/etc/kubernetes/kubeadmcfg.yaml"
        scp -P $K8S_sshPort $do_etcd_tmp_para/${K8S_node}kubeadmcfg.yaml $K8S_user@${K8S_ip1}:/etc/kubernetes/kubeadmcfg.yaml
        squawk 74 'etcd prep_20'
        prep_20-etcd-service-manager $K8S_user ${K8S_ip1} ${K8S_node} $K8S_sshPort
        squawk 74 'end etcd prep_20'

      elif [[ "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        # now for the external
        cat $do_etcd_tmp_para/endpoints.line \
        $do_etcd_tmp_para/external-endpoints.line \
        > $do_etcd_tmp_para/${K8S_node}endpoints.line


        if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
          squawk 20 'Major Version 1'
          if [[ $KUBE_MINOR_VER -lt 9 ]]; then
            croak 3  "$KUBE_MAJOR_VER.$KUBE_MINOR_VER is too old may not ever be supported"
          elif [[ $KUBE_MINOR_VER -eq 11 ]]; then
            kubeadmin_config_tmp=$(mktemp)
            my_master_ip=$( cat $KUBASH_CLUSTER_DIR/kube_primary) \
            KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
            load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
            my_KUBE_CIDR=$my_KUBE_CIDR \
            ENDPOINTS_LINES=$( cat $do_etcd_tmp_para/${K8S_node}endpoints.line) \
            envsubst  < $KUBASH_DIR/templates/kubeadm-config-external-1.11.yaml \
              > $do_etcd_tmp_para/${K8S_node}-external-kubeadmcfg.yaml
          elif [[ $KUBE_MINOR_VER -eq 12 ]]; then
            kubeadmin_config_tmp=$(mktemp)
            my_master_ip=$( cat $KUBASH_CLUSTER_DIR/kube_primary) \
            KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
            load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
            my_KUBE_CIDR=$my_KUBE_CIDR \
            ENDPOINTS_LINES=$( cat $do_etcd_tmp_para/${K8S_node}endpoints.line) \
            envsubst  < $KUBASH_DIR/templates/kubeadm-config-external-1.12.yaml \
              > $do_etcd_tmp_para/${K8S_node}-external-kubeadmcfg.yaml
          else
            squawk 10 "$KUBE_MAJOR_VER.$KUBE_MINOR_VER supported"
            kubeadmin_config_tmp=$(mktemp)
            my_master_ip=$my_master_ip \
            KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
            load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
            my_KUBE_CIDR=$my_KUBE_CIDR \
            ENDPOINTS_LINES=$( cat $KUBASH_CLUSTER_DIR/endpoints.line) \
            envsubst  < $KUBASH_DIR/templates/kubeadm-config-external-${KUBE_MAJOR_VER}.${KUBE_MINOR_VER}.yaml \
              > $do_etcd_tmp_para/${K8S_node}-external-kubeadmcfg.yaml
          fi
        elif [[ $MAJOR_VER -eq 0 ]]; then
          croak 3 'Major Version 0 unsupported'
        else
          croak 3 'Major Version Unknown'
        fi
        command2run="mkdir -p /tmp/${K8S_ip1}"
        sudo_command $my_master_port $my_master_user $my_master_ip "$command2run"
        squawk 25 "scp -P $my_master_port $do_etcd_tmp_para/${K8S_node}-external-kubeadmcfg.yaml $my_master_user@$my_master_ip:/tmp/${K8S_ip1}/kubeadmcfg.yaml"
        scp -P $my_master_port $do_etcd_tmp_para/${K8S_node}-external-kubeadmcfg.yaml $my_master_user@$my_master_ip:/tmp/${K8S_ip1}/kubeadmcfg.yaml
        squawk 25 "scp -P $K8S_sshPort $do_etcd_tmp_para/${K8S_node}-external-kubeadmcfg.yaml $K8S_user@${K8S_ip1}:/etc/kubernetes/kubeadmcfg.yaml"
        scp -P $K8S_sshPort $do_etcd_tmp_para/${K8S_node}-external-kubeadmcfg.yaml $K8S_user@${K8S_ip1}:/etc/kubernetes/kubeadmcfg.yaml
        squawk 75 'External master prep_20'
        prep_20-etcd-service-manager $K8S_user ${K8S_ip1} ${K8S_node} $K8S_sshPort
        squawk 75 'End create config loop'
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"
}

do_etcd () {
  squawk 3 " do_etcd"
  do_etcd_tmp_para=$(mktemp -d --suffix='.para.tmp' 2>/dev/null || mktemp -d -t '.para.tmp')
  touch $do_etcd_tmp_para/hopper
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi

  countprimarymaster=0
  countprimaryetcd=0
  countmaster=1
  countetcd=1
  set_csv_columns
  set_ip_files
  my_master_ip=$( cat $KUBASH_CLUSTER_DIR/kube_primary)
  my_master_user=$( cat $KUBASH_CLUSTER_DIR/kube_primary_user)
  my_master_port=$( cat $KUBASH_CLUSTER_DIR/kube_primary_port)
  # create  config files
  write_kubeadmcfg_yaml

  countprimarymaster=0
  set_csv_columns
  # First find the primary etcd master
  while IFS="," read -r $csv_columns
  do
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == "primary_master"  ]]; then
        if [[ "$countprimarymaster" -eq "0" ]]; then
          ((++countprimarymaster))
          prep_init_etcd $K8S_provisionerUser $K8S_ip1 $K8S_node $K8S_sshPort
          # save these values for clusterwide usage
          #kubash -n $KUBASH_CLUSTER_NAME --verbosity=$VERBOSITY prepetcd $K8S_provisionerUser $K8S_ip1 $K8S_node $K8S_sshPort
        else
          croak 3  'there should only be one primary master'
        fi
      fi
    else
      if [[ "$K8S_role" == "primary_etcd"  ]]; then
        if [[ "$countprimarymaster" -eq "0" ]]; then
          ((++countprimarymaster))
          prep_init_etcd $K8S_provisionerUser $K8S_ip1 $K8S_node $K8S_sshPort
          # save these values for clusterwide usage
          #kubash -n $KUBASH_CLUSTER_NAME --verbosity=$VERBOSITY prepetcd $K8S_provisionerUser $K8S_ip1 $K8S_node $K8S_sshPort
        else
          croak 3  'there should only be one primary etcd'
        fi
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"

  prepTMP=$(mktemp -d)
  touch $prepTMP/hopper
  # Then prep the other etcd hosts
  while IFS="," read -r $csv_columns
  do
    #squawk 3 "kubash -n $KUBASH_CLUSTER_NAME --verbosity=$VERBOSITY prepetcd $K8S_provisionerUser $K8S_ip1 $K8S_node $K8S_sshPort"
    #echo     "kubash -n $KUBASH_CLUSTER_NAME --verbosity=$VERBOSITY prepetcd $K8S_provisionerUser $K8S_ip1 $K8S_node $K8S_sshPort" >> $prepTMP/hopper
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      #if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' || "$K8S_role" == 'primary_etcd' ]]; then
      #if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_etcd' ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_etcd' ]]; then
          #squawk 19 "$K8S_node $K8S_role $K8S_cpuCount $K8S_Memory $K8S_network1 $K8S_mac1 $K8S_ip1 $K8S_provisionerHost $K8S_provisionerUser $K8S_sshPort $K8S_provisionerBasePath $K8S_os $K8S_virt $K8S_network2 $K8S_mac2 $K8S_ip2 $K8S_network3 $K8S_mac3 $K8S_ip3"
          squawk 3 "kubash -n $KUBASH_CLUSTER_NAME --verbosity=$VERBOSITY prepetcd $K8S_provisionerUser $K8S_ip1 $K8S_node $K8S_sshPort"
          echo     "kubash -n $KUBASH_CLUSTER_NAME --verbosity=$VERBOSITY prepetcd $K8S_provisionerUser $K8S_ip1 $K8S_node $K8S_sshPort" >> $prepTMP/hopper
      fi
    else
      #if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' || "$K8S_role" == 'primary_etcd' ]]; then
      #if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
      #if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
          squawk 3 "kubash -n $KUBASH_CLUSTER_NAME --verbosity=$VERBOSITY prepetcd $K8S_provisionerUser $K8S_ip1 $K8S_node $K8S_sshPort"
          echo     "kubash -n $KUBASH_CLUSTER_NAME --verbosity=$VERBOSITY prepetcd $K8S_provisionerUser $K8S_ip1 $K8S_node $K8S_sshPort" >> $prepTMP/hopper
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"
  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $prepTMP/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    #$PARALLEL  -j $PARALLEL_JOBS -- < $prepTMP/hopper
    bash $prepTMP/hopper
  else
    bash $prepTMP/hopper
  fi
  rm -Rf $prepTMP

  countprimarymaster=0
  set_csv_columns
  # First find the primary etcd master
  while IFS="," read -r $csv_columns
  do
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == "primary_master"  ]]; then
        if [[ "$countprimarymaster" -eq "0" ]]; then
          ((++countprimarymaster))
          kubash -n $KUBASH_CLUSTER_NAME --verbosity=$VERBOSITY prepetcd $K8S_provisionerUser $K8S_ip1 $K8S_node $K8S_sshPort
          finalize_etcd_gen_certs $K8S_sshPort $K8S_provisionerUser $K8S_ip1
        else
          croak 3  'there should only be one primary master'
        fi
      fi
    else
      if [[ "$K8S_role" == "primary_etcd"  ]]; then
        if [[ "$countprimarymaster" -eq "0" ]]; then
          ((++countprimarymaster))
          kubash -n $KUBASH_CLUSTER_NAME --verbosity=$VERBOSITY prepetcd $K8S_provisionerUser $K8S_ip1 $K8S_node $K8S_sshPort
          finalize_etcd_gen_certs $K8S_sshPort $K8S_provisionerUser $K8S_ip1
        else
          croak 3  'there should only be one primary etcd'
        fi
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"

  squawk 75 "create the manifests"
  command2run="kubeadm alpha phase etcd local --config=/etc/kubernetes/kubeadmcfg.yaml"
  if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
    do_command_in_parallel_on_role "primary_master"          "$command2run"
    do_command_in_parallel_on_role "primary_etcd"            "$command2run"
    do_command_in_parallel_on_role "master"                  "$command2run"
    do_command_in_parallel_on_role "etcd"                    "$command2run"
  else
    do_command_in_parallel_on_role "primary_etcd"            "$command2run"
    do_command_in_parallel_on_role "etcd"                    "$command2run"
  fi
  squawk 5 'sleep 33'
  sleep 33
}

do_primary_master () {
  squawk 3 " do_primary_master"
  do_master_count=0

  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "primary_master" ]]; then
      if [[ "$do_master_count" -lt "1" ]]; then
        squawk 9 "master_init_join $K8S_node $K8S_ip1 $K8S_provisionerUser $K8S_sshPort"
        master_init_join $K8S_node $K8S_ip1 $K8S_SU_USER $K8S_sshPort
      else
  echo 'There should only be one init master! Skipping this master'
        echo "master_init_join $K8S_node $K8S_ip1 $K8S_SU_USER $K8S_sshPort"
      fi
      ((++do_master_count))
    fi
  done <<< "$kubash_hosts_csv_slurped"
}

do_masters () {
  squawk 3 " do_masters"

  # hijack
  do_masters_in_parallel
}

do_scale_up_kube_dns () {
  squawk 3 "do_scale_up_kube_dns"
  do_scale_up_kube_dns=0

  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "master" || "$K8S_role" == "primary_master" ]]; then
    ((++do_scale_up_kube_dns))
    fi
  done <<< "$kubash_hosts_csv_slurped"

  kubectl scale --replicas=$do_scale_up_kube_dns -n kube-system  deployment/kube-dns
}

do_masters_in_parallel () {
  squawk 3 " do_masters_in_parallel"
  do_master_count=0


  do_master_tmp=$(mktemp -d)
  touch $do_master_tmp/hopper
  touch $do_master_tmp/hopper2
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    # get major minor vers
    if [[ "$K8S_role" == "primary_master" ]]; then
      get_major_minor_kube_version $K8S_user $K8S_ip1  $K8S_node $K8S_sshPort
      break
    fi
  done
  #command2run='sudo  rm /etc/kubernetes/pki/apiserver.crt'
  #do_command_in_parallel_on_role "master" "$command2run"
  if [[ -e "$KUBASH_CLUSTER_DIR/endpoints.line" ]]; then
    if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
      squawk 20 'Major Version 1'
      if [[ $KUBE_MINOR_VER -lt 9 ]]; then
        squawk 9 "$KUBE_MAJOR_VER.$KUBE_MINOR_VER is too old may not ever be supported"
        exit 1
      elif [[ $KUBE_MINOR_VER -eq 11 ]]; then
        squawk 11 "$KUBE_MAJOR_VER.$KUBE_MINOR_VER supported"
        kubeadmin_config_tmp=$(mktemp)
        my_master_ip=$my_master_ip \
        KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
        load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
        my_KUBE_CIDR=$my_KUBE_CIDR \
        ENDPOINTS_LINES=$( cat $KUBASH_CLUSTER_DIR/${K8S_node}endpoints.line ) \
        envsubst  < $KUBASH_DIR/templates/kubeadm-config-1.11.yaml \
          > $kubeadmin_config_tmp
      elif [[ $KUBE_MINOR_VER -eq 12 ]]; then
        squawk 12 "$KUBE_MAJOR_VER.$KUBE_MINOR_VER supported"
        kubeadmin_config_tmp=$(mktemp)
        my_master_ip=$my_master_ip \
        KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
        load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
        my_KUBE_CIDR=$my_KUBE_CIDR \
        ENDPOINTS_LINES=$( cat $KUBASH_CLUSTER_DIR/${K8S_node}endpoints.line ) \
        envsubst  < $KUBASH_DIR/templates/kubeadm-config-1.12.yaml \
          > $kubeadmin_config_tmp
      else
        squawk 10 "$KUBE_MAJOR_VER.$KUBE_MINOR_VER supported"
        kubeadmin_config_tmp=$(mktemp)
        my_master_ip=$my_master_ip \
        KUBERNETES_VERSION=$( cat $KUBASH_CLUSTER_DIR/kubernetes_version) \
        load_balancer_ip=$( cat $KUBASH_CLUSTER_DIR/kube_master1) \
        my_KUBE_CIDR=$my_KUBE_CIDR \
        ENDPOINTS_LINES=$( cat $KUBASH_CLUSTER_DIR/${K8S_node}endpoints.line ) \
        envsubst  < $KUBASH_DIR/templates/kubeadm-config-${KUBE_MAJOR_VER}.${KUBE_MINOR_VER}.yaml \
          > $kubeadmin_config_tmp
      fi
    elif [[ $MAJOR_VER -eq 0 ]]; then
      croak 3 'Major Version 0 unsupported'
    else
      croak 3 'Major Version Unknown'
    fi
    squawk 5 "copy_in_parallel_to_role master '$kubeadmin_config_tmp' '/tmp/config.yaml'"
    copy_in_parallel_to_role master "$kubeadmin_config_tmp" "/tmp/config.yaml"
    rm $kubeadmin_config_tmp
  fi
  command2run='systemctl stop kubectl'
  do_command_in_parallel_on_role "master" "$command2run"
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "master" ]]; then
      if [[ -e "$KUBASH_CLUSTER_DIR/endpoints.line" ]]; then
        my_KUBE_INIT="PATH=$K8S_SU_PATH $PSEUDO kubeadm init $KUBEADMIN_IGNORE_PREFLIGHT_CHECKS --config=/tmp/config.yaml"
        squawk 5 "$my_KUBE_INIT"
        echo "ssh -n $K8S_SU_USER@$K8S_ip1 '$my_KUBE_INIT'" >> $do_master_tmp/hopper
      else
        my_KUBE_INIT="PATH=$K8S_SU_PATH $PSEUDO kubeadm init $KUBEADMIN_IGNORE_PREFLIGHT_CHECKS --pod-network-cidr=$my_KUBE_CIDR"
        squawk 5 "$my_KUBE_INIT"
        echo "ssh -n $K8S_SU_USER@$K8S_ip1 '$my_KUBE_INIT'" >> $do_master_tmp/hopper
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"
  command2run='systemctl start kubectl'
  do_command_in_parallel_on_role "master" "$command2run"
  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $do_master_tmp/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $do_master_tmp/hopper
  else
    bash $do_master_tmp/hopper
  fi
  rm -Rf $do_master_tmp
  if [[ -e "$KUBASH_CLUSTER_DIR/endpoints.line" ]]; then
    do_command_in_parallel_on_role "master" "rm -f /tmp/config.yaml"
  fi
  #do_scale_up_kube_dns
}

do_nodes () {
  do_nodes_in_parallel
}

do_nodes_in_parallel () {
  do_nodes_tmp_para=$(mktemp -d)
  touch $do_nodes_tmp_para/hopper
  squawk 3 " do_nodes_in_parallel"
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  countzero_do_nodes=0
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "node" || "$K8S_role" == "ingress" ]]; then
      squawk 81 " K8S_role NODE"
      squawk 81 " K8S_role $K8S_role $K8S_ip1 $K8S_user $K8S_sshPort"
      echo "kubash -n $KUBASH_CLUSTER_NAME node_join --node-join-name $K8S_node --node-join-ip $K8S_ip1 --node-join-user $K8S_SU_USER --node-join-port $K8S_sshPort --node-join-role node" \
        >> $do_nodes_tmp_para/hopper
    else
      squawk 91 " K8S_role NOT NODE"
      squawk 91 " K8S_role $K8S_role $K8S_ip1 $K8S_user $K8S_sshPort"
    fi
    ((++countzero_do_nodes))
    squawk 3 " count $countzero_do_nodes"
  done <<< "$kubash_hosts_csv_slurped"

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $do_nodes_tmp_para/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $do_nodes_tmp_para/hopper
  else
    bash $do_nodes_tmp_para/hopper
  fi
  rm -Rf $do_nodes_tmp_para
}

do_command_in_parallel () {
  do_command_tmp_para=$(mktemp -d)
  command2run=$1
  touch $do_command_tmp_para/hopper
  squawk 3 " do_command_in_parallel $@"
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    squawk 219 'slurp empty'
    hosts_csv_slurp
  else
    squawk 219 "host slurp $(echo $kubash_hosts_csv_slurped)"
  fi
  countzero_do_nodes=0
  squawk 120 'Start while loop'
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    ((++countzero_do_nodes))
    squawk 219 " count $countzero_do_nodes"
    squawk 205 "ssh -n -p $K8S_sshPort $K8S_SU_USER@$K8S_ip1 \"sudo bash -c '$command2run'\""
    echo "ssh -n -p $K8S_sshPort $K8S_SU_USER@$K8S_ip1 \"sudo bash -c '$command2run'\""\
        >> $do_command_tmp_para/hopper
  done <<< "$kubash_hosts_csv_slurped"

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $do_command_tmp_para/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $do_command_tmp_para/hopper
  else
    bash $do_command_tmp_para/hopper
  fi
  rm -Rf $do_command_tmp_para
}

do_command () {
  squawk 3 " do_command $@"
  if [[ ! $# -eq 4 ]]; then
    croak 3  "do_command $@ <--- arguments does not equal 4!!!"
  fi
  do_command_port=$1
  do_command_user=$2
  do_command_host=$3
  command2run=$4
  if [[ "$do_command_host" == "localhost" ]]; then
    squawk 105 "bash -c '$command2run'"
    bash -c "$command2run"
  else
    squawk 105 "ssh -n -p $do_command_port $do_command_user@$do_command_host \"bash -c '$command2run'\""
    ssh -n -p $do_command_port $do_command_user@$do_command_host "bash -c '$command2run'"
  fi
}

sudo_command () {
  if [[ ! $# -eq 4 ]]; then
    croak 3  "sudo_command $@ <--- arguments does not equal 4!!!"
  fi
  squawk 3 " sudo_command '$1' '$2' '$3 '$4'"
  sudo_command_port=$1
  sudo_command_user=$2
  sudo_command_host=$3
  command2run=$4
  if [[ "$sudo_command_host" == "localhost" ]]; then
    squawk 105 "sudo bash -c '$command2run'"
    sudo bash -c "$command2run"
  else
    squawk 105 "ssh -n -p $sudo_command_port $sudo_command_user@$sudo_command_host \"$PSEUDO bash -l -c '$command2run'\""
    ssh -n -p $sudo_command_port $sudo_command_user@$sudo_command_host "$PSEUDO bash -l -c '$command2run'"
  fi
}

copy_known_hosts () {
  squawk 15 'copy known_hosts to all servers'
  copy_in_parallel_to_all ~/.ssh/known_hosts /tmp/known_hosts
  command2run="cp -v /tmp/known_hosts /root/.ssh/known_hosts"
  do_command_in_parallel "$command2run"
  command2run="mv -v /tmp/known_hosts /home/$K8S_SU_USER/.ssh/known_hosts"
  do_command_in_parallel "$command2run"
}

copy_in_parallel_to_all () {
  copy_in_to_all_tmp_para=$(mktemp -d)
  file2copy=$(realpath $1)
  destination=$2
  touch $copy_in_to_all_tmp_para/hopper
  squawk 3 " copy_in_parallel_to_all $@"
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    squawk 205 "rsync $KUBASH_RSYNC_OPTS 'ssh -p $K8S_sshPort' $file2copy $K8S_SU_USER@$K8S_ip1:$destination"
    echo "rsync $KUBASH_RSYNC_OPTS 'ssh -p $K8S_sshPort' $file2copy $K8S_SU_USER@$K8S_ip1:$destination"\
      >> $copy_in_to_all_tmp_para/hopper
  done <<< "$kubash_hosts_csv_slurped"

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $copy_in_to_all_tmp_para/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $copy_in_to_all_tmp_para/hopper
  else
    bash $copy_in_to_all_tmp_para/hopper
  fi
  rm -Rf $copy_in_to_all_tmp_para
}

copy_in_parallel_to_role () {
  copy_in_to_role_tmp_para=$(mktemp -d)
  role2copy2=$1
  file2copy=$(realpath $2)
  destination=$3
  touch $copy_in_to_role_tmp_para/hopper
  squawk 3 " copy_in_parallel_to_role $@"
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "$role2copy2" ]]; then
      squawk 219 " count $countzero_do_nodes"
      squawk 205 "rsync $KUBASH_RSYNC_OPTS 'ssh -p $K8S_sshPort' $file2copy $K8S_SU_USER@$K8S_ip1:$destination"
      echo "rsync $KUBASH_RSYNC_OPTS 'ssh -p $K8S_sshPort' $file2copy $K8S_SU_USER@$K8S_ip1:$destination"\
        >> $copy_in_to_role_tmp_para/hopper
    fi
  done <<< "$kubash_hosts_csv_slurped"

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $copy_in_to_role_tmp_para/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $copy_in_to_role_tmp_para/hopper
  else
    bash $copy_in_to_role_tmp_para/hopper
  fi
  rm -Rf $copy_in_to_role_tmp_para
}

copy_in_parallel_to_os () {
  copy_in_to_os_tmp_para=$(mktemp -d)
  os2copy2=$1
  file2copy=$(realpath $2)
  destination=$3
  touch $copy_in_to_os_tmp_para/hopper
  squawk 3 " copy_in_parallel_to_os $@"
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_os" == "$os2copy2" ]]; then
      squawk 219 " count $countzero_do_nodes"
      squawk 205 "rsync $KUBASH_RSYNC_OPTS 'ssh -p $K8S_sshPort' $file2copy $K8S_SU_USER@$K8S_ip1:$destination"
      echo "rsync $KUBASH_RSYNC_OPTS 'ssh -p $K8S_sshPort' $file2copy $K8S_SU_USER@$K8S_ip1:$destination"\
        >> $copy_in_to_os_tmp_para/hopper
    fi
  done <<< "$kubash_hosts_csv_slurped"

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $copy_in_to_os_tmp_para/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $copy_in_to_os_tmp_para/hopper
  else
    bash $copy_in_to_os_tmp_para/hopper
  fi
  rm -Rf $copy_in_to_os_tmp_para
}

do_command_in_parallel_on_role () {
  do_command_on_role_tmp_para=$(mktemp -d)
  role2runiton=$1
  command2run=$2
  touch $do_command_on_role_tmp_para/hopper
  squawk 3 " do_command_in_parallel_on_role $@"
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "$role2runiton" ]]; then
      squawk 219 " count $countzero_do_nodes"
      squawk 205 "ssh -n -p $K8S_sshPort $K8S_SU_USER@$K8S_ip1 \"sudo bash -c '$command2run'\""
      echo "ssh -n -p $K8S_sshPort $K8S_SU_USER@$K8S_ip1 \"sudo bash -c '$command2run'\""\
        >> $do_command_on_role_tmp_para/hopper
    fi
  done <<< "$kubash_hosts_csv_slurped"

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $do_command_on_role_tmp_para/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $do_command_on_role_tmp_para/hopper
  else
    bash $do_command_on_role_tmp_para/hopper
  fi
  rm -Rf $do_command_on_role_tmp_para
}

do_test () {
  squawk 3 " do_test $@"
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    echo "K8S_node=$K8S_node
K8S_role=$K8S_role
K8S_cpuCount=$K8S_cpuCount
K8S_Memory=$K8S_Memory
K8S_sshPort=$K8S_sshPort
K8S_network1=$K8S_network1
K8S_mac1=$K8S_mac1
K8S_ip1=$K8S_ip1
K8S_provisionerHost=$K8S_provisionerHost
K8S_SU_USER=$K8S_SU_USER
K8S_provisionerPort=$K8S_provisionerPort
K8S_provisionerBasePath=$K8S_provisionerBasePath
K8S_os=$K8S_os
K8S_virt=$K8S_virt
K8S_network2=$K8S_network2
K8S_mac2=$K8S_mac2
K8S_ip2=$K8S_ip2
K8S_network3=$K8S_network3
K8S_mac3=$K8S_mac3
K8S_ip3=$K8S_ipv3"
  done <<< "$kubash_hosts_csv_slurped"
}

do_command_in_parallel_on_os () {
  do_command_on_os_tmp_para=$(mktemp -d)
  os2runiton=$1
  command2run=$2
  touch $do_command_on_os_tmp_para/hopper
  squawk 3 " do_command_in_parallel $@"
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_os" == "$os2runiton" ]]; then
      squawk 219 " count $countzero_do_nodes"
      squawk 205 "ssh -n -p $K8S_sshPort $K8S_SU_USER@$K8S_ip1 \"sudo bash -c '$command2run'\""
      echo "ssh -n -p $K8S_sshPort $K8S_SU_USER@$K8S_ip1 \"sudo bash -c '$command2run'\""\
        >> $do_command_on_os_tmp_para/hopper
    fi
  done <<< "$kubash_hosts_csv_slurped"

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $do_command_on_os_tmp_para/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $do_command_on_os_tmp_para/hopper
  else
    bash $do_command_on_os_tmp_para/hopper
  fi
  rm -Rf $do_command_on_os_tmp_para
}

prep () {
  squawk 5 " prep"
  set_csv_columns
  hosts_csv_slurp
  while IFS="," read -r $csv_columns
  do
    preppy $K8S_node $K8S_ip1 $K8S_sshPort
  done <<< "$kubash_hosts_csv_slurped"
}

preppy () {
  squawk 7 "preppy $@"
  node_name=$1
  node_ip=$2
  node_port=$3
  #removestalekeys $node_ip
  #ssh-keyscan -p $node_port $node_ip >> ~/.ssh/known_hosts
  scanner $node_ip $node_port
}

do_decom () {
  if [[ "$ANSWER_YES" == "yes" ]]; then
    decom_kvm
    rm -f $KUBASH_HOSTS_CSV
    rm -f $KUBASH_ANSIBLE_HOSTS
    rm -f $KUBASH_CLUSTER_CONFIG
  else
    read -p "This will destroy all VMs defined in the $KUBASH_HOSTS_CSV. Are you sure? [y/N] " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      decom_kvm
      rm -f $KUBASH_HOSTS_CSV
      rm -f $KUBASH_ANSIBLE_HOSTS
      rm -f $KUBASH_CLUSTER_CONFIG
    fi
  fi
}

do_metallb () {
    if [[ METALLB_INSTALLATION_METHOD = 'helm' ]]; then
      KUBECONFIG=$KUBECONFIG \
        helm install --name metallb stable/metallb
    else
      kubectl --kubeconfig=$KUBECONFIG apply -f \
        https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml
    fi
}

do_istio () {
    cd $KUBASH_DIR/submodules/istio/install
    cd kubernetes/helm
    kubectl --kubeconfig=$KUBECONFIG apply -f \
      istio
}

do_efk () {
    cd $KUBASH_DIR/submodules/openebs/k8s/demo/efk
    kubectl --kubeconfig=$KUBECONFIG apply -f \
      es
    kubectl --kubeconfig=$KUBECONFIG apply -f \
      fluentd
    kubectl --kubeconfig=$KUBECONFIG apply -f \
      kibana
}

do_rook () {
    kubectl --kubeconfig=$KUBECONFIG create -f \
      https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/minio/operator.yaml

    KUBECONFIG=$KUBECONFIG \
        $KUBASH_DIR/w8s/generic.w8 rook-minio-operator rook-minio-system

    kubectl --kubeconfig=$KUBECONFIG create -f \
      https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/minio/object-store.yaml
}

do_openebs () {
    if [[ OPENEBS_INSTALLATION_METHOD = 'helm' ]]; then
    kubash_context
    KUBECONFIG=$KUBECONFIG \
    helm install \
      --namespace openebs \
      --name $KUBASH_OPENEBS_NAME \
      stable/openebs
    else
      kubectl --kubeconfig=$KUBECONFIG create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-operator.yaml
    fi
    kubectl --kubeconfig=$KUBECONFIG create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-storageclasses.yaml
}

activate_monitoring () {
  # Prometheus
  cd $KUBASH_DIR/submodules/openebs/k8s/openebs-monitoring/configs
  kubectl --kubeconfig=$KUBECONFIG create -f \
    prometheus-config.yaml
  kubectl --kubeconfig=$KUBECONFIG create -f \
    prometheus-env.yaml
  kubectl --kubeconfig=$KUBECONFIG create -f \
    prometheus-alert-rules.yaml
  kubectl --kubeconfig=$KUBECONFIG create -f \
    alertmanager-templates.yaml
  kubectl --kubeconfig=$KUBECONFIG create -f \
    alertmanager-config.yaml
  cd $KUBASH_DIR/submodules/openebs/k8s/openebs-monitoring
  kubectl --kubeconfig=$KUBECONFIG create -f \
    prometheus-operator.yaml
  kubectl --kubeconfig=$KUBECONFIG create -f \
    alertmanager.yaml
  kubectl --kubeconfig=$KUBECONFIG create -f \
    grafana-operator.yaml
}
