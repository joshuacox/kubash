#!/usr/bin/env bash

grab_kube_pki_ext_etcd_sub () {
  grab_sub_USER=$1
  grab_sub_HOST=$2
  grab_sub_PORT=$3
  # Make a list of required etcd certificate files for subsequent masters
  # break indentation
    command2run='cat << EOF > sub-pki-files.txt
/etc/kubernetes/pki/ca.crt
/etc/kubernetes/pki/ca.key
/etc/kubernetes/pki/sa.key
/etc/kubernetes/pki/sa.pub
/etc/kubernetes/pki/front-proxy-ca.crt
/etc/kubernetes/pki/front-proxy-ca.key
EOF'
  # unbreak indentation

  squawk 55 "ssh ${grab_sub_USER}@${grab_sub_HOST} $command2run"
  sudo_command ${grab_sub_PORT} ${grab_sub_USER} ${grab_sub_HOST} "$command2run"

  # create the archive
  command2run="tar -czf /tmp/sub-pki.tar.gz -T sub-pki-files.txt"
  sudo_command ${grab_sub_PORT} ${grab_sub_USER} ${grab_sub_HOST} "$command2run"
  squawk 55 "scp -P ${grab_sub_PORT} ${grab_sub_USER}@${grab_sub_HOST}/tmp/sub-pki.tar.gz ${KUBASH_CLUSTER_DIR}/sub-pki.tar.gz"
  scp -P ${grab_sub_PORT} ${grab_sub_USER}@${grab_sub_HOST}:/tmp/sub-pki.tar.gz ${KUBASH_CLUSTER_DIR}/sub-pki.tar.gz
  command2run="rm /tmp/sub-pki.tar.gz"
}

grab_kube_pki_stacked_method () {
  grab_USER=$1
  grab_HOST=$2
  grab_PORT=$3
  # Make a list of required etcd certificate files
  # break indentation
    command2run='cat << EOF > kube-pki-files.txt
/etc/kubernetes/pki/ca.crt
/etc/kubernetes/pki/ca.key
/etc/kubernetes/pki/sa.key
/etc/kubernetes/pki/sa.pub
/etc/kubernetes/pki/front-proxy-ca.crt
/etc/kubernetes/pki/front-proxy-ca.key
/etc/kubernetes/pki/etcd/ca.crt
/etc/kubernetes/pki/etcd/ca.key
/etc/kubernetes/admin.conf
EOF'
  # unbreak indentation
#/etc/kubernetes/controller-manager.conf
#/etc/kubernetes/scheduler.conf

  squawk 55 "ssh ${grab_USER}@${grab_HOST} $command2run"
  sudo_command ${grab_PORT} ${grab_USER} ${grab_HOST} "$command2run"

  # create the archive
  command2run="tar -czf /tmp/kube-pki.tar.gz -T kube-pki-files.txt"
  sudo_command ${grab_PORT} ${grab_USER} ${grab_HOST} "$command2run"
  squawk 55 "scp -P ${grab_PORT} ${grab_USER}@${grab_HOST}/tmp/kube-pki.tar.gz ${KUBASH_CLUSTER_DIR}/kube-pki.tar.gz"
  scp -P ${grab_PORT} ${grab_USER}@${grab_HOST}:/tmp/kube-pki.tar.gz ${KUBASH_CLUSTER_DIR}/kube-pki.tar.gz
  command2run="rm /tmp/kube-pki.tar.gz"
  #sudo_command ${grab_PORT} ${grab_USER} ${grab_HOST} "$command2run"
}

push_kube_pki_stacked_method () {
  push_USER=$1
  push_HOST=$2
  push_PORT=$3
  squawk 9 "rsync $KUBASH_RSYNC_OPTS ssh -p $push_PORT ${KUBASH_CLUSTER_DIR}/kube-pki.tar.gz $push_USER@$push_HOST:/tmp/"
  rsync $KUBASH_RSYNC_OPTS "ssh -p $push_PORT" ${KUBASH_CLUSTER_DIR}/kube-pki.tar.gz $push_USER@$push_HOST:/tmp/
  #command2run='mkdir -p /etc/kubernetes/pki && tar -xzvf /tmp/kube-pki.tar.gz -C /etc/kubernetes/pki --strip-components=3'
  command2run='mkdir -p /etc/kubernetes/pki && cd / && tar -xzvf /tmp/kube-pki.tar.gz'
  sudo_command ${push_PORT} ${push_USER} ${push_HOST} "$command2run"
  command2run='rm /tmp/kube-pki.tar.gz'
  #sudo_command ${push_PORT} ${push_USER} ${push_HOST} "$command2run"
}

push_kube_pki_ext_etcd_sub () {
  push_sub_USER=$1
  push_sub_HOST=$2
  push_sub_PORT=$3
  squawk 9 "rsync $KUBASH_RSYNC_OPTS ssh -p $push_sub_PORT ${KUBASH_CLUSTER_DIR}/sub-pki.tar.gz $push_sub_USER@$push_sub_HOST:/tmp/"
  rsync $KUBASH_RSYNC_OPTS "ssh -p $push_sub_PORT" ${KUBASH_CLUSTER_DIR}/sub-pki.tar.gz $push_sub_USER@$push_sub_HOST:/tmp/
  command2run='mkdir -p /etc/kubernetes/pki && cd / && tar -xzvf /tmp/sub-pki.tar.gz'
  sudo_command ${push_sub_PORT} ${push_sub_USER} ${push_sub_HOST} "$command2run"
  command2run='rm /tmp/sub-pki.tar.gz'
  #sudo_command ${push_sub_PORT} ${push_sub_USER} ${push_sub_HOST} "$command2run"
}

grab_pki_ext_etcd_method () {
  grab_pki_ext_etcdUSER=$1
  grab_pki_ext_etcdHOST=$2
  grab_pki_ext_etcdPORT=$3
  # Make a list of required etcd certificate files
  # break indentation
    command2run='cat << EOF > etcd-pki-files.txt
/etc/kubernetes/pki/etcd/ca.crt
/etc/kubernetes/pki/apiserver-etcd-client.crt
/etc/kubernetes/pki/apiserver-etcd-client.key
EOF'
  # unbreak indentation
  squawk 55 "ssh ${grab_pki_ext_etcdUSER}@${grab_pki_ext_etcdHOST} $command2run"
  sudo_command ${grab_pki_ext_etcdPORT} ${grab_pki_ext_etcdUSER} ${grab_pki_ext_etcdHOST} "$command2run"

  # create the archive
  command2run="tar -czf /tmp/etcd-pki.tar.gz -T etcd-pki-files.txt"
  sudo_command ${grab_pki_ext_etcdPORT} ${grab_pki_ext_etcdUSER} ${grab_pki_ext_etcdHOST} "$command2run"
  squawk 55 "scp -P ${grab_pki_ext_etcdPORT} ${grab_pki_ext_etcdUSER}@${grab_pki_ext_etcdHOST}/tmp/etcd-pki.tar.gz ${KUBASH_CLUSTER_DIR}/etcd-pki.tar.gz"
  scp -P ${grab_pki_ext_etcdPORT} ${grab_pki_ext_etcdUSER}@${grab_pki_ext_etcdHOST}:/tmp/etcd-pki.tar.gz ${KUBASH_CLUSTER_DIR}/etcd-pki.tar.gz
  command2run="rm /tmp/etcd-pki.tar.gz"
  sudo_command ${grab_pki_ext_etcdPORT} ${grab_pki_ext_etcdUSER} ${grab_pki_ext_etcdHOST} "$command2run"
}

push_pki_ext_etcd_method () {
  push_pki_ext_etcd_USER=$1
  push_pki_ext_etcd_HOST=$2
  push_pki_ext_etcd_PORT=$3
  squawk 9 "rsync $KUBASH_RSYNC_OPTS ssh -p $push_pki_ext_etcd_PORT ${KUBASH_CLUSTER_DIR}/etcd-pki.tar.gz $push_pki_ext_etcd_USER@$push_pki_ext_etcd_HOST:/tmp/"
  rsync $KUBASH_RSYNC_OPTS "ssh -p $push_pki_ext_etcd_PORT" ${KUBASH_CLUSTER_DIR}/etcd-pki.tar.gz $push_pki_ext_etcd_USER@$push_pki_ext_etcd_HOST:/tmp/
  #command2run='mkdir -p /etc/kubernetes/pki && tar -xzvf /tmp/etcd-pki.tar.gz -C /etc/kubernetes/pki --strip-components=3'
  command2run='mkdir -p /etc/kubernetes/pki && cd / && tar -xzvf /tmp/etcd-pki.tar.gz'
  sudo_command ${push_pki_ext_etcd_PORT} ${push_pki_ext_etcd_USER} ${push_pki_ext_etcd_HOST} "$command2run"
  command2run='rm /tmp/etcd-pki.tar.gz'
  sudo_command ${push_pki_ext_etcd_PORT} ${push_pki_ext_etcd_USER} ${push_pki_ext_etcd_HOST} "$command2run"
}

determine_api_version () {
  if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
    squawk 20 'Major Version 1'
    if [[ $KUBE_MINOR_VER -lt 9 ]]; then
      croak 3  "$KUBE_MINOR_VER is too old may not ever be supported"
    elif [[ $KUBE_MINOR_VER -eq 9 ]]; then
      squawk 75 kubeadm_apiVersion="kubeadm.k8s.io/v1alpha1"
      export kubeadm_apiVersion="kubeadm.k8s.io/v1alpha1"
      kubeadm_cfg_kind=MasterConfiguration
      echo "$KUBE_MINOR_VER is too old and is not supported"
    elif [[ $KUBE_MINOR_VER -eq 10 ]]; then
      squawk 75 kubeadm_apiVersion="kubeadm.k8s.io/v1alpha1"
      export kubeadm_apiVersion="kubeadm.k8s.io/v1alpha1"
      kubeadm_cfg_kind=MasterConfiguration
      echo "$KUBE_MINOR_VER is too old and is not supported"
    elif [[ $KUBE_MINOR_VER -eq 11 ]]; then
      squawk 75 kubeadm_apiVersion="kubeadm.k8s.io/v1alpha2"
      export kubeadm_apiVersion="kubeadm.k8s.io/v1alpha2"
      kubeadm_cfg_kind=MasterConfiguration
      echo "$KUBE_MINOR_VER is too old and is not supported"
    elif [[ $KUBE_MINOR_VER -ge 12 ]]; then
      squawk 75 kubeadm_apiVersion="kubeadm.k8s.io/v1alpha3"
      export kubeadm_apiVersion="kubeadm.k8s.io/v1alpha3"
      kubeadm_cfg_kind=ClusterConfiguration
    else
      croak 3  "$KUBE_MINOR_VER not supported yet"
    fi
  elif [[ $MAJOR_VER -eq 0 ]]; then
    croak 3 'Major Version 0 unsupported'
  else
    croak 3 'Major Version Unknown'
  fi
}

etcd_kubernetes_ext_etcd_method () {
  etcd_kubernetes_13_ext_etcd_method
}

etcd_kubernetes_12_ext_etcd_method () {
  etcd_test_tmp=$(mktemp -d)
  INIT_USER=root
  #my_KUBE_CIDR="10.244.0.0/16"
  set_csv_columns
  etc_count_zero=0
  master_count_zero=0
  node_count_zero=0
  while IFS="," read -r $csv_columns
  do
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' || "$K8S_role" == 'primary_etcd' ]]; then
        ETCDHOSTS[$etc_count_zero]=$K8S_ip1
        ETCDNAMES[$etc_count_zero]=$K8S_node
        ETCDPORTS[$etc_count_zero]=$K8S_sshPort
        MASTERHOSTS[$master_count_zero]=$K8S_ip1
        MASTERNAMES[$master_count_zero]=$K8S_node
        MASTERPORTS[$master_count_zero]=$K8S_sshPort
        ((++etc_count_zero))
        ((++master_count_zero))
      elif [[ "$K8S_role" == 'node' ]]; then
        NODEHOSTS[$node_count_zero]=$K8S_ip1
        NODENAMES[$node_count_zero]=$K8S_node
        NODEPORTS[$node_count_zero]=$K8S_sshPort
        ((++node_count_zero))
      fi
    else
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
        ETCDHOSTS[$etc_count_zero]=$K8S_ip1
        ETCDNAMES[$etc_count_zero]=$K8S_node
        ETCDPORTS[$etc_count_zero]=$K8S_sshPort
        ((++etc_count_zero))
      elif [[ "$K8S_role" == 'node' ]]; then
        NODEHOSTS[$node_count_zero]=$K8S_ip1
        NODENAMES[$node_count_zero]=$K8S_node
        NODEPORTS[$node_count_zero]=$K8S_sshPort
        ((++node_count_zero))
      elif [[ "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        MASTERHOSTS[$master_count_zero]=$K8S_ip1
        MASTERNAMES[$master_count_zero]=$K8S_node
        MASTERPORTS[$master_count_zero]=$K8S_sshPort
        ((++master_count_zero))
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"
  echo $ETCDHOSTS
  sleep 33
  get_major_minor_kube_version $K8S_user ${MASTERHOSTS[0]} ${MASTERNAMES[0]} ${MASTERPORTS[0]}
  determine_api_version

  echo -n "            initial-cluster: " > $etcd_test_tmp/initial-cluster.head
  count_etcd=0
  countetcdnodes=0
  while IFS="," read -r $csv_columns
  do
    echo "- \"${K8S_ip1}\"" >> $etcd_test_tmp/apiservercertsans.line
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        if [[ $countetcdnodes -gt 0 ]]; then
          printf ',' >> $etcd_test_tmp/initial-cluster.line
        fi
        if [[ "$ETCD_TLS" == 'true' ]]; then
          printf "${K8S_node}=https://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          echo "      - https://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
        else
          printf "${K8S_node}=https://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          echo "      - https://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
          #printf "${K8S_node}=http://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          #echo "      - http://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
        fi
        ((++countetcdnodes))
      fi
    else
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
        if [[ $countetcdnodes -gt 0 ]]; then
          printf ',' >> $etcd_test_tmp/initial-cluster.line
        fi
        if [[ "$ETCD_TLS" == 'true' ]]; then
          printf "${K8S_node}=https://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          echo "      - https://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
        else
          printf "${K8S_node}=https://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          echo "      - https://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
          #printf "${K8S_node}=http://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          #echo "      - http://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
        fi
        ((++countetcdnodes))
      fi
    fi
    ((++count_etcd))
  done <<< "$kubash_hosts_csv_slurped"
  if [[ "$ETCD_TLS" == 'true' ]]; then
    echo '      caFile: /etc/kubernetes/pki/etcd/ca.crt
      certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
      keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key' \
    >> $etcd_test_tmp/endpoints.line
  else
    echo '      caFile: /etc/kubernetes/pki/etcd/ca.crt
      certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
      keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key' \
    >> $etcd_test_tmp/endpoints.line
  fi
  printf " \n" >> $etcd_test_tmp/initial-cluster.line
  initial_cluster_line=$(cat $etcd_test_tmp/initial-cluster.head $etcd_test_tmp/initial-cluster.line)
  api_server_cert_sans_line=$(cat $etcd_test_tmp/apiservercertsans.line)
  endpoints_line=$(cat $etcd_test_tmp/endpoints.line)
  rm $etcd_test_tmp/initial-cluster.head $etcd_test_tmp/initial-cluster.line $etcd_test_tmp/apiservercertsans.line $etcd_test_tmp/endpoints.line

  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    # Create temp directories to store files that will end up on other hosts.
    squawk 55 "mkdir -p $etcd_test_tmp/${HOST}/"
    mkdir -p $etcd_test_tmp/${HOST}/

    # break indentation
    command2run='cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --address=127.0.0.1 --pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true
Restart=always
EOF'
    # unbreak indentation

    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"

    # break indentation
    #command2run='cat << EOF > /var/lib/kubelet/config.yaml
  #kind: KubeletConfiguration
  #apiVersion: kubelet.config.k8s.io/v1beta1
  #address: 127.0.0.1
  #staticpodpath: /etc/kubernetes/manifests
  #EOF'
    # unbreak indentation
    #squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    #ssh ${INIT_USER}@${HOST} "$command2run"
  done

  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    squawk 55 "mkdir -p $etcd_test_tmp/${HOST}/"
    mkdir -p $etcd_test_tmp/${HOST}/
    # break indentation
    #command2run='cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
#[Service]
#ExecStart=
#ExecStart=/usr/bin/kubelet --address=127.0.0.1 --pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true
#Restart=always
#EOF'
    ## unbreak indentation
    #squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    #ssh ${INIT_USER}@${HOST} "$command2run"
  done


  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    NAME=${ETCDNAMES[$i]}
    cat << EOF > $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
apiVersion: "$kubeadm_apiVersion"
kind: $kubeadm_cfg_kind
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
$initial_cluster_line
            initial-cluster-state: new
            name: ${NAME}
EOF
  if [[ "$ETCD_TLS" == 'true' ]]; then
    echo "            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380" \
     >> $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
  elif [[ "$ETCD_TLS" == 'calamazoo' ]]; then
    # neutered
    echo "            listen-peer-urls: http://${HOST}:2380
            listen-client-urls: http://${HOST}:2379
            advertise-client-urls: http://${HOST}:2379
            initial-advertise-peer-urls: http://${HOST}:2380" \
     >> $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
  else
    echo "            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380" \
     >> $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
  fi
    command2run='systemctl daemon-reload'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
    command2run='systemctl restart kubelet'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
  done
  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    NAME=${MASTERNAMES[$i]}
    if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
      if [[ $KUBE_MINOR_VER -gt 11 ]]; then
       if [[ $SEMAPHORE_FLAG_KILL = 'not_gonna_be_it' ]]; then
        cat << EOF > $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
apiVersion: $kubeadm_apiVersion
kind: InitConfiguration
apiEndpoint:
  advertiseAddress: ${HOST}
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: ${NAME}
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
EOF
      fi
     fi
   fi
    cat << EOF >> $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
apiVersion: $kubeadm_apiVersion
kind: $kubeadm_cfg_kind
apiServerCertSANs:
- "127.0.0.1"
$api_server_cert_sans_line
controlPlaneEndpoint: "${MASTERHOSTS[0]}:6443"
etcd:
  external:
      endpoints:
$endpoints_line
networking:
  podSubnet: $my_KUBE_CIDR
EOF
    command2run='systemctl daemon-reload'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
    #command2run='systemctl restart kubelet'
    #squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    #ssh ${INIT_USER}@${HOST} "$command2run"
  done

  command2run='kubeadm alpha phase certs etcd-ca'
  squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
  ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"

  squawk 5 "copy pki directory to host 0"
  command2run='tar zcf - pki'
  PREV_PWD=$(pwd)
  cd $etcd_test_tmp/${ETCDHOSTS[0]}/
  squawk 56 "ssh ${INIT_USER}@${HOST} cd /etc/kubernetes;$command2run|tar pzxvf -"
  ssh ${INIT_USER}@${ETCDHOSTS[0]} "cd /etc/kubernetes;$command2run"|tar pzxvf -
  cd $PREV_PWD

  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    PREV_PWD=$(pwd)
    cd $etcd_test_tmp/
    squawk 55 "tar zcf - ${HOST} | ssh ${INIT_USER}@${ETCDHOSTS[0]} cd /tmp; tar pzxvf -"
    tar zcf - ${HOST} | ssh ${INIT_USER}@${ETCDHOSTS[0]} "cd /tmp; tar pzxvf -"
    cd $PREV_PWD
  done

  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    command2run="kubeadm alpha phase certs etcd-server --config=/tmp/${HOST}/kubeadmcfg.yaml"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    command2run="kubeadm alpha phase certs etcd-peer --config=/tmp/${HOST}/kubeadmcfg.yaml"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    command2run="kubeadm alpha phase certs etcd-healthcheck-client --config=/tmp/${HOST}/kubeadmcfg.yaml"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    command2run="kubeadm alpha phase certs apiserver-etcd-client --config=/tmp/${HOST}/kubeadmcfg.yaml"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    command2run="rsync -a /etc/kubernetes/pki /tmp/${HOST}/"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    squawk 5 "cleanup non-reusable certificates"
    command2run="find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    squawk 5 "clean up certs that should not be copied off this host"
    command2run="find /tmp/${HOST} -name ca.key -type f -delete"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    #if [[ $i -eq 0 ]]; then
      #grab_pki_ext_etcd_method $K8S_user ${ETCDHOSTS[0]} ${ETCDPORTS[0]}
    #fi
  done

  squawk 5 "gather the pki and configs"
  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    PREV_PWD=$(pwd)
    cd $etcd_test_tmp/
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} cd /tmp;tar zcf - ${HOST} | tar pzxvf -"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "cd /tmp;tar zcf - ${HOST}" | tar pzxvf -
    cd $PREV_PWD
  done
  squawk 5 "distribute the pki and configs to etcd hosts"
  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    PREV_PWD=$(pwd)
    cd $etcd_test_tmp/${HOST}
    squawk 55 "tar zcf - pki | ssh ${INIT_USER}@${HOST} cd /etc/kubernetes; tar pzxvf -"
    tar zcf - pki | ssh ${INIT_USER}@${HOST} "cd /etc/kubernetes; tar pzxvf -"
    squawk 55 "tar zcf - kubeadmcfg.yaml | ssh ${INIT_USER}@${HOST} cd /etc/kubernetes; tar pzxvf -"
    tar zcf - kubeadmcfg.yaml | ssh ${INIT_USER}@${HOST} "cd /etc/kubernetes; tar pzxvf -"
    cd $PREV_PWD
  done

  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    squawk 55 "ssh ${INIT_USER}@${HOST} sudo chown -R root:root /etc/kubernetes/pki"
    ssh ${INIT_USER}@${HOST} "sudo chown -R root:root /etc/kubernetes/pki"
    squawk 55 "ssh ${INIT_USER}@${HOST} kubeadm alpha phase etcd local --config=/etc/kubernetes/kubeadmcfg.yaml"
    ssh ${INIT_USER}@${HOST} "kubeadm alpha phase etcd local --config=/etc/kubernetes/kubeadmcfg.yaml"
  done
  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    command2run='ls -alh /root'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
    command2run='ls -Ralh /etc/kubernetes/pki'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
  done

  command2run="kubeadm config images pull"
  squawk 55 "$command2run"
  for i in "${!MASTERHOSTS[@]}"; do
    ssh ${INIT_USER}@${MASTERHOSTS[$i]} "$command2run"
  done
  squawk 33 "sleep 33 - give etcd a chance to settle"
  #sleep 33
  sleep 11

  command2run="docker run --rm  \
    --net host \
    -v /etc/kubernetes:/etc/kubernetes quay.io/coreos/etcd:v3.2.18 etcdctl \
    --cert-file /etc/kubernetes/pki/etcd/peer.crt \
    --key-file /etc/kubernetes/pki/etcd/peer.key \
    --ca-file /etc/kubernetes/pki/etcd/ca.crt \
    --endpoints https://${ETCDHOSTS[0]}:2379 cluster-health"

  squawk 55 'To test etcd run this commmand'
  squawk 55 "$command2run"
  #squawk 55 "ssh -p ${ETCDPORTS[0]} ${K8S_User}@${ETCDHOSTS[0]} $command2run"
  #ssh -p ${ETCDPORTS[0]} ${K8S_User}@${ETCDHOSTS[0]} "$command2run"
  squawk 55 "sudo_command ${ETCDPORTS[0]} $K8S_user ${ETCDHOSTS[0]} $command2run"
  sudo_command ${ETCDPORTS[0]} $K8S_user ${ETCDHOSTS[0]} "$command2run"
  grab_pki_ext_etcd_method $K8S_user ${ETCDHOSTS[0]} ${ETCDPORTS[0]}
  #grab_kube_pki_stacked_method $K8S_user ${ETCDHOSTS[0]} ${ETCDPORTS[0]}

  # distribute the pki and configs
  #for i in "${!MASTERHOSTS[@]}"; do
    #squawk 55 "cp -a $etcd_test_tmp/${ETCDHOSTS[0]}/pki $etcd_test_tmp/${MASTERHOSTS[$i]}/"
    #cp -a $etcd_test_tmp/${ETCDHOSTS[0]}/pki $etcd_test_tmp/${MASTERHOSTS[$i]}/
  #done
  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    PREV_PWD=$(pwd)
    squawk 55 "push_pki_ext_etcd_method  $K8S_user ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}"
    push_pki_ext_etcd_method  $K8S_user ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
    cd $etcd_test_tmp/${HOST}
    #squawk 55 "tar zcf - pki | ssh ${INIT_USER}@${HOST} cd /etc/kubernetes; tar pzxvf -"
    #tar zcf - pki | ssh ${INIT_USER}@${HOST} "cd /etc/kubernetes; tar pzxvf -"
    squawk 55 "tar zcf - kubeadmcfg.yaml | ssh ${INIT_USER}@${HOST} cd /etc/kubernetes; tar pzxvf -"
    tar zcf - kubeadmcfg.yaml | ssh ${INIT_USER}@${HOST} "cd /etc/kubernetes; tar pzxvf -"
    cd $PREV_PWD
  done
  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    #command2run='systemctl daemon-reload'
    #echo "ssh ${INIT_USER}@${HOST} $command2run"
  #  ssh ${INIT_USER}@${HOST} "$command2run"
    #command2run='systemctl stop kubelet'
    #echo "ssh ${INIT_USER}@${HOST} $command2run"
  #  ssh ${INIT_USER}@${HOST} "$command2run"
  done

  if [[ "$VERBOSITY" -ge "10" ]] ; then
    command2run="kubeadm init --dry-run --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-etcd.yaml,ExternalEtcdVersion --config /etc/kubernetes/kubeadmcfg.yaml"
    squawk 105 "$command2run"
    ssh ${INIT_USER}@${MASTERHOSTS[0]} "$command2run"
  fi
  #sleep 11
  #command2run="kubeadm init  --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-etcd.yaml,ExternalEtcdVersion --config /etc/kubernetes/kubeadmcfg.yaml"
  #master_grab_kube_config ${MASTERNAMES[0]} ${MASTERHOSTS[0]} $K8S_user ${MASTERPORTS[0]}
  #sudo_command ${MASTERPORTS[0]} $K8S_user ${MASTERHOSTS[0]} "$command2run"
  #command2run="kubeadm init --config /etc/kubernetes/kubeadmcfg.yaml"
  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    NAME=${MASTERNAMES[$i]}
    if [[ -e "$KUBASH_CLUSTER_DIR/master_join.sh" ]]; then
      rsync $KUBASH_RSYNC_OPTS "ssh -p ${MASTERPORTS[$i]}" $KUBASH_CLUSTER_DIR/master_join.sh $INIT_USER@$HOST:/tmp/
      push_kube_pki_ext_etcd_sub ${INIT_USER} ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
      #command2run="ls -Rl /etc/kubernetes"
      #sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
      #command2run="rm -fv /etc/kubernetes/kubelet.conf"
      #sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
      my_KUBE_INIT="bash /tmp/master_join.sh"
      squawk 5 "kube init --> $my_KUBE_INIT"
      ssh -n -p ${MASTERPORTS[$i]} root@${HOST} "$my_KUBE_INIT" 2>&1 | tee $etcd_test_tmp/${HOST}-rawresults.k8s
      w8_node $my_node_name
    else
      #command2run="kubeadm init --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-etcd.yaml,ExternalEtcdVersion --config /etc/kubernetes/kubeadmcfg.yaml"
      #echo "$command2run"
      #ssh ${INIT_USER}@${MASTERHOSTS[0]} "$command2run"
      #sudo_command ${MASTERPORTS[0]} $K8S_user ${MASTERHOSTS[0]} "$command2run"


      #my_KUBE_INIT="PATH=$K8S_SU_PATH $PSEUDO kubeadm init $KUBEADMIN_IGNORE_PREFLIGHT_CHECKS --config=/etc/kubernetes/kubeadmcfg.yaml"
      my_KUBE_INIT="kubeadm init --config=/etc/kubernetes/kubeadmcfg.yaml"
      squawk 5 "master kube init --> $my_KUBE_INIT"
      my_grep='kubeadm join .* --token'
      #run_join=$(ssh -n ${INIT_USER}@${HOST} "$my_KUBE_INIT" | tee $etcd_test_tmp/rawresults.k8s | grep -- "$my_grep")
      ssh -n -p ${MASTERPORTS[$i]} root@${HOST} "$my_KUBE_INIT" 2>&1 | tee $etcd_test_tmp/${HOST}-rawresults.k8s
      #cat $etcd_test_tmp/${HOST}-rawresults.k8s | grep -- "$my_grep"
      run_join=$(cat $etcd_test_tmp/${HOST}-rawresults.k8s | grep -P -- "$my_grep")
      join_token=$(cat $etcd_test_tmp/${HOST}-rawresults.k8s \
        | grep -P -- "$my_grep" \
        | sed 's/\(.*\)--token\ \(\S*\)\ --discovery-token-ca-cert-hash\ .*/\2/')
      if [[ -z "$run_join" ]]; then
        horizontal_rule
        croak 3  'kubeadm init failed!'
      else
        echo $run_join > $KUBASH_CLUSTER_DIR/join.sh
        echo $run_join > $KUBASH_CLUSTER_DIR/master_join.sh
        #sed -i 's/$/ --ignore-preflight-errors=FileAvailable--etc-kubernetes-pki-ca.crt/' $KUBASH_CLUSTER_DIR/join.sh
        sed -i 's/$/ --experimental-control-plane/' $KUBASH_CLUSTER_DIR/master_join.sh
        echo $join_token > $KUBASH_CLUSTER_DIR/join_token
        master_grab_kube_config ${NAME} ${HOST} ${INIT_USER} ${MASTERPORTS[$i]}
        grab_kube_pki_ext_etcd_sub ${INIT_USER} ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
        squawk 120 "rsync $KUBASH_RSYNC_OPTS ssh -p ${MASTERPORTS[$i]} $KUBASH_DIR/w8s/generic.w8 $INIT_USER@$HOST:/tmp/"
        rsync $KUBASH_RSYNC_OPTS "ssh -p ${MASTERPORTS[$i]}" $KUBASH_DIR/w8s/generic.w8 $INIT_USER@$HOST:/tmp/
        command2run='mv /tmp/generic.w8 /root/'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-controller kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-scheduler kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-apiserver kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        sleep 11
        squawk 5 "do_net before other masters"
        w8_kubectl
        do_net
        w8_node $my_node_name
      fi
    fi
  done
  while IFS="," read -r $csv_columns
  do
    squawk 85 "ROLE $K8S_role $K8S_user $K8S_ip1 $K8S_sshPort"
    if [[ "$K8S_role" == 'node' ]]; then
      squawk 101 'neutered'
      #squawk 65 "push kube pki ext etcd sub $K8S_user $K8S_ip1 $K8S_sshPort"
      #push_pki_ext_etcd_method   $K8S_user $K8S_ip1 $K8S_sshPort
      #push_kube_pki_ext_etcd_sub $K8S_user $K8S_ip1 $K8S_sshPort
    fi
  done <<< "$kubash_hosts_csv_slurped"
  rm -Rf $etcd_test_tmp
}

etcd_kubernetes_13_ext_etcd_method () {
  etcd_test_tmp=$(mktemp -d)
  INIT_USER=root
  set_csv_columns
  etc_count_zero=0
  master_count_zero=0
  node_count_zero=0
  while IFS="," read -r $csv_columns
  do
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' || "$K8S_role" == 'primary_etcd' ]]; then
        ETCDHOSTS[$etc_count_zero]=$K8S_ip1
        ETCDNAMES[$etc_count_zero]=$K8S_node
        ETCDPORTS[$etc_count_zero]=$K8S_sshPort
        MASTERHOSTS[$master_count_zero]=$K8S_ip1
        MASTERNAMES[$master_count_zero]=$K8S_node
        MASTERPORTS[$master_count_zero]=$K8S_sshPort
        ((++etc_count_zero))
        ((++master_count_zero))
      elif [[ "$K8S_role" == 'node' ]]; then
        NODEHOSTS[$node_count_zero]=$K8S_ip1
        NODENAMES[$node_count_zero]=$K8S_node
        NODEPORTS[$node_count_zero]=$K8S_sshPort
        ((++node_count_zero))
      fi
    else
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
        ETCDHOSTS[$etc_count_zero]=$K8S_ip1
        ETCDNAMES[$etc_count_zero]=$K8S_node
        ETCDPORTS[$etc_count_zero]=$K8S_sshPort
        ((++etc_count_zero))
      elif [[ "$K8S_role" == 'node' ]]; then
        NODEHOSTS[$node_count_zero]=$K8S_ip1
        NODENAMES[$node_count_zero]=$K8S_node
        NODEPORTS[$node_count_zero]=$K8S_sshPort
        ((++node_count_zero))
      elif [[ "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        MASTERHOSTS[$master_count_zero]=$K8S_ip1
        MASTERNAMES[$master_count_zero]=$K8S_node
        MASTERPORTS[$master_count_zero]=$K8S_sshPort
        ((++master_count_zero))
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"
  echo $ETCDHOSTS
  sleep 33
  get_major_minor_kube_version $K8S_user ${MASTERHOSTS[0]} ${MASTERNAMES[0]} ${MASTERPORTS[0]}
  determine_api_version

  echo -n "            initial-cluster: " > $etcd_test_tmp/initial-cluster.head
  count_etcd=0
  countetcdnodes=0
  while IFS="," read -r $csv_columns
  do
    echo "- \"${K8S_ip1}\"" >> $etcd_test_tmp/apiservercertsans.line
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        if [[ $countetcdnodes -gt 0 ]]; then
          printf ',' >> $etcd_test_tmp/initial-cluster.line
        fi
        if [[ "$ETCD_TLS" == 'true' ]]; then
          printf "${K8S_node}=https://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          echo "      - https://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
        else
          printf "${K8S_node}=https://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          echo "      - https://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
        fi
        ((++countetcdnodes))
      fi
    else
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
        if [[ $countetcdnodes -gt 0 ]]; then
          printf ',' >> $etcd_test_tmp/initial-cluster.line
        fi
        if [[ "$ETCD_TLS" == 'true' ]]; then
          printf "${K8S_node}=https://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          echo "      - https://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
        else
          printf "${K8S_node}=https://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          echo "      - https://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
        fi
        ((++countetcdnodes))
      fi
    fi
    ((++count_etcd))
  done <<< "$kubash_hosts_csv_slurped"
  if [[ "$ETCD_TLS" == 'true' ]]; then
    echo '      caFile: /etc/kubernetes/pki/etcd/ca.crt
      certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
      keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key' \
    >> $etcd_test_tmp/endpoints.line
  else
    echo '      caFile: /etc/kubernetes/pki/etcd/ca.crt
      certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
      keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key' \
    >> $etcd_test_tmp/endpoints.line
  fi
  printf " \n" >> $etcd_test_tmp/initial-cluster.line
  initial_cluster_line=$(cat $etcd_test_tmp/initial-cluster.head $etcd_test_tmp/initial-cluster.line)
  api_server_cert_sans_line=$(cat $etcd_test_tmp/apiservercertsans.line)
  endpoints_line=$(cat $etcd_test_tmp/endpoints.line)
  rm $etcd_test_tmp/initial-cluster.head $etcd_test_tmp/initial-cluster.line $etcd_test_tmp/apiservercertsans.line $etcd_test_tmp/endpoints.line

  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    # Create temp directories to store files that will end up on other hosts.
    squawk 55 "mkdir -p $etcd_test_tmp/${HOST}/"
    mkdir -p $etcd_test_tmp/${HOST}/
    # break indentation
    command2run='cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --address=127.0.0.1 --pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true
Restart=always
EOF'
    # unbreak indentation
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
  done

  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    squawk 55 "mkdir -p $etcd_test_tmp/${HOST}/"
    mkdir -p $etcd_test_tmp/${HOST}/
  done


  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    NAME=${ETCDNAMES[$i]}
    cat << EOF > $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
apiVersion: "$kubeadm_apiVersion"
kind: $kubeadm_cfg_kind
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
$initial_cluster_line
            initial-cluster-state: new
            name: ${NAME}
EOF
  if [[ "$ETCD_TLS" == 'true' ]]; then
    echo "            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380" \
     >> $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
  elif [[ "$ETCD_TLS" == 'calamazoo' ]]; then
    # neutered
    echo "            listen-peer-urls: http://${HOST}:2380
            listen-client-urls: http://${HOST}:2379
            advertise-client-urls: http://${HOST}:2379
            initial-advertise-peer-urls: http://${HOST}:2380" \
     >> $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
  else
    echo "            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380" \
     >> $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
  fi
    command2run='systemctl daemon-reload'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
    command2run='systemctl restart kubelet'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
  done
  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    NAME=${MASTERNAMES[$i]}
    if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
      if [[ $KUBE_MINOR_VER -gt 11 ]]; then
       if [[ $SEMAPHORE_FLAG_KILL = 'not_gonna_be_it' ]]; then
        cat << EOF > $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
apiVersion: $kubeadm_apiVersion
kind: InitConfiguration
apiEndpoint:
  advertiseAddress: ${HOST}
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: ${NAME}
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
EOF
      fi
     fi
   fi
    cat << EOF >> $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
apiVersion: $kubeadm_apiVersion
kind: $kubeadm_cfg_kind
apiServerCertSANs:
- "127.0.0.1"
$api_server_cert_sans_line
controlPlaneEndpoint: "${MASTERHOSTS[0]}:6443"
etcd:
  external:
      endpoints:
$endpoints_line
networking:
  podSubnet: $my_KUBE_CIDR
EOF
    command2run='systemctl daemon-reload'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
  done

  command2run='kubeadm init phase certs etcd-ca'
  squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
  ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"

  squawk 5 "copy pki directory to host 0"
  command2run='tar zcf - pki'
  PREV_PWD=$(pwd)
  cd $etcd_test_tmp/${ETCDHOSTS[0]}/
  squawk 56 "ssh ${INIT_USER}@${HOST} cd /etc/kubernetes;$command2run|tar pzxvf -"
  ssh ${INIT_USER}@${ETCDHOSTS[0]} "cd /etc/kubernetes;$command2run"|tar pzxvf -
  cd $PREV_PWD

  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    PREV_PWD=$(pwd)
    cd $etcd_test_tmp/
    squawk 55 "tar zcf - ${HOST} | ssh ${INIT_USER}@${ETCDHOSTS[0]} cd /tmp; tar pzxvf -"
    tar zcf - ${HOST} | ssh ${INIT_USER}@${ETCDHOSTS[0]} "cd /tmp; tar pzxvf -"
    cd $PREV_PWD
  done

  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    command2run="kubeadm init phase certs etcd-server --config=/tmp/${HOST}/kubeadmcfg.yaml"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    command2run="kubeadm init phase certs etcd-peer --config=/tmp/${HOST}/kubeadmcfg.yaml"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    command2run="kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST}/kubeadmcfg.yaml"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    command2run="kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST}/kubeadmcfg.yaml"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    command2run="rsync -a /etc/kubernetes/pki /tmp/${HOST}/"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    squawk 5 "cleanup non-reusable certificates"
    command2run="find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    squawk 5 "clean up certs that should not be copied off this host"
    command2run="find /tmp/${HOST} -name ca.key -type f -delete"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
  done

  squawk 5 "gather the pki and configs"
  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    PREV_PWD=$(pwd)
    cd $etcd_test_tmp/
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} cd /tmp;tar zcf - ${HOST} | tar pzxvf -"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "cd /tmp;tar zcf - ${HOST}" | tar pzxvf -
    cd $PREV_PWD
  done
  squawk 5 "distribute the pki and configs to etcd hosts"
  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    PREV_PWD=$(pwd)
    cd $etcd_test_tmp/${HOST}
    squawk 55 "tar zcf - pki | ssh ${INIT_USER}@${HOST} cd /etc/kubernetes; tar pzxvf -"
    tar zcf - pki | ssh ${INIT_USER}@${HOST} "cd /etc/kubernetes; tar pzxvf -"
    squawk 55 "tar zcf - kubeadmcfg.yaml | ssh ${INIT_USER}@${HOST} cd /etc/kubernetes; tar pzxvf -"
    tar zcf - kubeadmcfg.yaml | ssh ${INIT_USER}@${HOST} "cd /etc/kubernetes; tar pzxvf -"
    cd $PREV_PWD
  done

  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    squawk 55 "ssh ${INIT_USER}@${HOST} sudo chown -R root:root /etc/kubernetes/pki"
    ssh ${INIT_USER}@${HOST} "sudo chown -R root:root /etc/kubernetes/pki"
    squawk 55 "ssh ${INIT_USER}@${HOST} kubeadm init phase etcd local --config=/etc/kubernetes/kubeadmcfg.yaml"
    ssh ${INIT_USER}@${HOST} "kubeadm init phase etcd local --config=/etc/kubernetes/kubeadmcfg.yaml"
  done
  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    command2run='ls -alh /root'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
    command2run='ls -Ralh /etc/kubernetes/pki'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
  done

  command2run="kubeadm config images pull"
  squawk 55 "$command2run"
  for i in "${!MASTERHOSTS[@]}"; do
    ssh ${INIT_USER}@${MASTERHOSTS[$i]} "$command2run"
  done
  squawk 33 "sleep 33 - give etcd a chance to settle"
  sleep 11

  command2run="docker run --rm  \
    --net host \
    -v /etc/kubernetes:/etc/kubernetes quay.io/coreos/etcd:v3.2.18 etcdctl \
    --cert-file /etc/kubernetes/pki/etcd/peer.crt \
    --key-file /etc/kubernetes/pki/etcd/peer.key \
    --ca-file /etc/kubernetes/pki/etcd/ca.crt \
    --endpoints https://${ETCDHOSTS[0]}:2379 cluster-health"

  squawk 55 'To test etcd run this commmand'
  squawk 55 "$command2run"
  squawk 55 "sudo_command ${ETCDPORTS[0]} $K8S_user ${ETCDHOSTS[0]} $command2run"
  sudo_command ${ETCDPORTS[0]} $K8S_user ${ETCDHOSTS[0]} "$command2run"
  grab_pki_ext_etcd_method $K8S_user ${ETCDHOSTS[0]} ${ETCDPORTS[0]}

  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    PREV_PWD=$(pwd)
    squawk 55 "push_pki_ext_etcd_method  $K8S_user ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}"
    push_pki_ext_etcd_method  $K8S_user ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
    cd $etcd_test_tmp/${HOST}
    squawk 55 "tar zcf - kubeadmcfg.yaml | ssh ${INIT_USER}@${HOST} cd /etc/kubernetes; tar pzxvf -"
    tar zcf - kubeadmcfg.yaml | ssh ${INIT_USER}@${HOST} "cd /etc/kubernetes; tar pzxvf -"
    cd $PREV_PWD
  done
  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
  done

  if [[ "$VERBOSITY" -ge "10" ]] ; then
    command2run="kubeadm init --dry-run --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-etcd.yaml,ExternalEtcdVersion --config /etc/kubernetes/kubeadmcfg.yaml"
    squawk 105 "$command2run"
    ssh ${INIT_USER}@${MASTERHOSTS[0]} "$command2run"
  fi
  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    NAME=${MASTERNAMES[$i]}
    if [[ -e "$KUBASH_CLUSTER_DIR/master_join.sh" ]]; then
      rsync $KUBASH_RSYNC_OPTS "ssh -p ${MASTERPORTS[$i]}" $KUBASH_CLUSTER_DIR/master_join.sh $INIT_USER@$HOST:/tmp/
      push_kube_pki_ext_etcd_sub ${INIT_USER} ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
      my_KUBE_INIT="bash /tmp/master_join.sh"
      squawk 5 "kube init --> $my_KUBE_INIT"
      ssh -n -p ${MASTERPORTS[$i]} root@${HOST} "$my_KUBE_INIT" 2>&1 | tee $etcd_test_tmp/${HOST}-rawresults.k8s
      w8_node $my_node_name
    else
      my_KUBE_INIT="kubeadm init --config=/etc/kubernetes/kubeadmcfg.yaml"
      squawk 5 "master kube init --> $my_KUBE_INIT"
      my_grep='kubeadm join .* --token'
      ssh -n -p ${MASTERPORTS[$i]} root@${HOST} "$my_KUBE_INIT" 2>&1 | tee $etcd_test_tmp/${HOST}-rawresults.k8s
      run_join=$(cat $etcd_test_tmp/${HOST}-rawresults.k8s | grep -P -- "$my_grep")
      join_token=$(cat $etcd_test_tmp/${HOST}-rawresults.k8s \
        | grep -P -- "$my_grep" \
        | sed 's/\(.*\)--token\ \(\S*\)\ --discovery-token-ca-cert-hash\ .*/\2/')
      if [[ -z "$run_join" ]]; then
        horizontal_rule
        croak 3  'kubeadm init failed!'
      else
        echo $run_join > $KUBASH_CLUSTER_DIR/join.sh
        echo $run_join > $KUBASH_CLUSTER_DIR/master_join.sh
        sed -i 's/$/ --experimental-control-plane/' $KUBASH_CLUSTER_DIR/master_join.sh
        echo $join_token > $KUBASH_CLUSTER_DIR/join_token
        master_grab_kube_config ${NAME} ${HOST} ${INIT_USER} ${MASTERPORTS[$i]}
        grab_kube_pki_ext_etcd_sub ${INIT_USER} ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
        squawk 120 "rsync $KUBASH_RSYNC_OPTS ssh -p ${MASTERPORTS[$i]} $KUBASH_DIR/w8s/generic.w8 $INIT_USER@$HOST:/tmp/"
        rsync $KUBASH_RSYNC_OPTS "ssh -p ${MASTERPORTS[$i]}" $KUBASH_DIR/w8s/generic.w8 $INIT_USER@$HOST:/tmp/
        command2run='mv /tmp/generic.w8 /root/'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-proxy kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-apiserver kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-controller kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-scheduler kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        sleep 11
        squawk 5 "do_net before other masters"
        w8_kubectl
        do_net
        w8_node $my_node_name
      fi
    fi
  done
  rm -Rf $etcd_test_tmp
}

etcd_kubernetes_13_ext_etcd_method () {
  etcd_test_tmp=$(mktemp -d)
  INIT_USER=root
  set_csv_columns
  etc_count_zero=0
  master_count_zero=0
  node_count_zero=0
  while IFS="," read -r $csv_columns
  do
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' || "$K8S_role" == 'primary_etcd' ]]; then
        ETCDHOSTS[$etc_count_zero]=$K8S_ip1
        ETCDNAMES[$etc_count_zero]=$K8S_node
        ETCDPORTS[$etc_count_zero]=$K8S_sshPort
        MASTERHOSTS[$master_count_zero]=$K8S_ip1
        MASTERNAMES[$master_count_zero]=$K8S_node
        MASTERPORTS[$master_count_zero]=$K8S_sshPort
        ((++etc_count_zero))
        ((++master_count_zero))
      elif [[ "$K8S_role" == 'node' ]]; then
        NODEHOSTS[$node_count_zero]=$K8S_ip1
        NODENAMES[$node_count_zero]=$K8S_node
        NODEPORTS[$node_count_zero]=$K8S_sshPort
        ((++node_count_zero))
      fi
    else
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
        ETCDHOSTS[$etc_count_zero]=$K8S_ip1
        ETCDNAMES[$etc_count_zero]=$K8S_node
        ETCDPORTS[$etc_count_zero]=$K8S_sshPort
        ((++etc_count_zero))
      elif [[ "$K8S_role" == 'node' ]]; then
        NODEHOSTS[$node_count_zero]=$K8S_ip1
        NODENAMES[$node_count_zero]=$K8S_node
        NODEPORTS[$node_count_zero]=$K8S_sshPort
        ((++node_count_zero))
      elif [[ "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        MASTERHOSTS[$master_count_zero]=$K8S_ip1
        MASTERNAMES[$master_count_zero]=$K8S_node
        MASTERPORTS[$master_count_zero]=$K8S_sshPort
        ((++master_count_zero))
      fi
    fi
  done <<< "$kubash_hosts_csv_slurped"
  echo $ETCDHOSTS
  sleep 33
  get_major_minor_kube_version $K8S_user ${MASTERHOSTS[0]} ${MASTERNAMES[0]} ${MASTERPORTS[0]}
  determine_api_version

  echo -n "            initial-cluster: " > $etcd_test_tmp/initial-cluster.head
  count_etcd=0
  countetcdnodes=0
  while IFS="," read -r $csv_columns
  do
    echo "- \"${K8S_ip1}\"" >> $etcd_test_tmp/apiservercertsans.line
    if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' ]]; then
        if [[ $countetcdnodes -gt 0 ]]; then
          printf ',' >> $etcd_test_tmp/initial-cluster.line
        fi
        if [[ "$ETCD_TLS" == 'true' ]]; then
          printf "${K8S_node}=https://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          echo "      - https://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
        else
          printf "${K8S_node}=https://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          echo "      - https://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
        fi
        ((++countetcdnodes))
      fi
    else
      if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'primary_etcd' ]]; then
        if [[ $countetcdnodes -gt 0 ]]; then
          printf ',' >> $etcd_test_tmp/initial-cluster.line
        fi
        if [[ "$ETCD_TLS" == 'true' ]]; then
          printf "${K8S_node}=https://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          echo "      - https://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
        else
          printf "${K8S_node}=https://${K8S_ip1}:2380" >> $etcd_test_tmp/initial-cluster.line
          echo "      - https://${K8S_ip1}:2379" >> $etcd_test_tmp/endpoints.line
        fi
        ((++countetcdnodes))
      fi
    fi
    ((++count_etcd))
  done <<< "$kubash_hosts_csv_slurped"
  if [[ "$ETCD_TLS" == 'true' ]]; then
    echo '      caFile: /etc/kubernetes/pki/etcd/ca.crt
      certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
      keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key' \
    >> $etcd_test_tmp/endpoints.line
  else
    echo '      caFile: /etc/kubernetes/pki/etcd/ca.crt
      certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
      keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key' \
    >> $etcd_test_tmp/endpoints.line
  fi
  printf " \n" >> $etcd_test_tmp/initial-cluster.line
  initial_cluster_line=$(cat $etcd_test_tmp/initial-cluster.head $etcd_test_tmp/initial-cluster.line)
  api_server_cert_sans_line=$(cat $etcd_test_tmp/apiservercertsans.line)
  endpoints_line=$(cat $etcd_test_tmp/endpoints.line)
  rm $etcd_test_tmp/initial-cluster.head $etcd_test_tmp/initial-cluster.line $etcd_test_tmp/apiservercertsans.line $etcd_test_tmp/endpoints.line

  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    # Create temp directories to store files that will end up on other hosts.
    squawk 55 "mkdir -p $etcd_test_tmp/${HOST}/"
    mkdir -p $etcd_test_tmp/${HOST}/
    # break indentation
    command2run='cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --address=127.0.0.1 --pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true
Restart=always
EOF'
    # unbreak indentation
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
  done

  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    squawk 55 "mkdir -p $etcd_test_tmp/${HOST}/"
    mkdir -p $etcd_test_tmp/${HOST}/
  done


  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    NAME=${ETCDNAMES[$i]}
    cat << EOF > $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
apiVersion: "$kubeadm_apiVersion"
kind: $kubeadm_cfg_kind
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
$initial_cluster_line
            initial-cluster-state: new
            name: ${NAME}
EOF
  if [[ "$ETCD_TLS" == 'true' ]]; then
    echo "            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380" \
     >> $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
  elif [[ "$ETCD_TLS" == 'calamazoo' ]]; then
    # neutered
    echo "            listen-peer-urls: http://${HOST}:2380
            listen-client-urls: http://${HOST}:2379
            advertise-client-urls: http://${HOST}:2379
            initial-advertise-peer-urls: http://${HOST}:2380" \
     >> $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
  else
    echo "            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380" \
     >> $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
  fi
    command2run='systemctl daemon-reload'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
    command2run='systemctl restart kubelet'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
  done
  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    NAME=${MASTERNAMES[$i]}
    if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
      if [[ $KUBE_MINOR_VER -gt 11 ]]; then
       if [[ $SEMAPHORE_FLAG_KILL = 'not_gonna_be_it' ]]; then
        cat << EOF > $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
apiVersion: $kubeadm_apiVersion
kind: InitConfiguration
apiEndpoint:
  advertiseAddress: ${HOST}
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: ${NAME}
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
EOF
      fi
     fi
   fi
    cat << EOF >> $etcd_test_tmp/${HOST}/kubeadmcfg.yaml
apiVersion: $kubeadm_apiVersion
kind: $kubeadm_cfg_kind
apiServerCertSANs:
- "127.0.0.1"
$api_server_cert_sans_line
controlPlaneEndpoint: "${MASTERHOSTS[0]}:6443"
etcd:
  external:
      endpoints:
$endpoints_line
networking:
  podSubnet: $my_KUBE_CIDR
EOF
    command2run='systemctl daemon-reload'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
  done

  command2run='kubeadm init phase certs etcd-ca'
  squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
  ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"

  squawk 5 "copy pki directory to host 0"
  command2run='tar zcf - pki'
  PREV_PWD=$(pwd)
  cd $etcd_test_tmp/${ETCDHOSTS[0]}/
  squawk 56 "ssh ${INIT_USER}@${HOST} cd /etc/kubernetes;$command2run|tar pzxvf -"
  ssh ${INIT_USER}@${ETCDHOSTS[0]} "cd /etc/kubernetes;$command2run"|tar pzxvf -
  cd $PREV_PWD

  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    PREV_PWD=$(pwd)
    cd $etcd_test_tmp/
    squawk 55 "tar zcf - ${HOST} | ssh ${INIT_USER}@${ETCDHOSTS[0]} cd /tmp; tar pzxvf -"
    tar zcf - ${HOST} | ssh ${INIT_USER}@${ETCDHOSTS[0]} "cd /tmp; tar pzxvf -"
    cd $PREV_PWD
  done

  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    command2run="kubeadm init phase certs etcd-server --config=/tmp/${HOST}/kubeadmcfg.yaml"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    command2run="kubeadm init phase certs etcd-peer --config=/tmp/${HOST}/kubeadmcfg.yaml"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    command2run="kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST}/kubeadmcfg.yaml"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    command2run="kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST}/kubeadmcfg.yaml"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    command2run="rsync -a /etc/kubernetes/pki /tmp/${HOST}/"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    squawk 5 "cleanup non-reusable certificates"
    command2run="find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
    squawk 5 "clean up certs that should not be copied off this host"
    command2run="find /tmp/${HOST} -name ca.key -type f -delete"
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} $command2run"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "$command2run"
  done

  squawk 5 "gather the pki and configs"
  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    PREV_PWD=$(pwd)
    cd $etcd_test_tmp/
    squawk 55 "ssh ${INIT_USER}@${ETCDHOSTS[0]} cd /tmp;tar zcf - ${HOST} | tar pzxvf -"
    ssh ${INIT_USER}@${ETCDHOSTS[0]} "cd /tmp;tar zcf - ${HOST}" | tar pzxvf -
    cd $PREV_PWD
  done
  squawk 5 "distribute the pki and configs to etcd hosts"
  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    PREV_PWD=$(pwd)
    cd $etcd_test_tmp/${HOST}
    squawk 55 "tar zcf - pki | ssh ${INIT_USER}@${HOST} cd /etc/kubernetes; tar pzxvf -"
    tar zcf - pki | ssh ${INIT_USER}@${HOST} "cd /etc/kubernetes; tar pzxvf -"
    squawk 55 "tar zcf - kubeadmcfg.yaml | ssh ${INIT_USER}@${HOST} cd /etc/kubernetes; tar pzxvf -"
    tar zcf - kubeadmcfg.yaml | ssh ${INIT_USER}@${HOST} "cd /etc/kubernetes; tar pzxvf -"
    cd $PREV_PWD
  done

  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    squawk 55 "ssh ${INIT_USER}@${HOST} sudo chown -R root:root /etc/kubernetes/pki"
    ssh ${INIT_USER}@${HOST} "sudo chown -R root:root /etc/kubernetes/pki"
    squawk 55 "ssh ${INIT_USER}@${HOST} kubeadm init phase etcd local --config=/etc/kubernetes/kubeadmcfg.yaml"
    ssh ${INIT_USER}@${HOST} "kubeadm init phase etcd local --config=/etc/kubernetes/kubeadmcfg.yaml"
  done
  for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    command2run='ls -alh /root'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
    command2run='ls -Ralh /etc/kubernetes/pki'
    squawk 55 "ssh ${INIT_USER}@${HOST} $command2run"
    ssh ${INIT_USER}@${HOST} "$command2run"
  done

  command2run="kubeadm config images pull"
  squawk 55 "$command2run"
  for i in "${!MASTERHOSTS[@]}"; do
    ssh ${INIT_USER}@${MASTERHOSTS[$i]} "$command2run"
  done
  squawk 33 "sleep 33 - give etcd a chance to settle"
  sleep 11

  command2run="docker run --rm  \
    --net host \
    -v /etc/kubernetes:/etc/kubernetes quay.io/coreos/etcd:v3.2.18 etcdctl \
    --cert-file /etc/kubernetes/pki/etcd/peer.crt \
    --key-file /etc/kubernetes/pki/etcd/peer.key \
    --ca-file /etc/kubernetes/pki/etcd/ca.crt \
    --endpoints https://${ETCDHOSTS[0]}:2379 cluster-health"

  squawk 55 'To test etcd run this commmand'
  squawk 55 "$command2run"
  squawk 55 "sudo_command ${ETCDPORTS[0]} $K8S_user ${ETCDHOSTS[0]} $command2run"
  sudo_command ${ETCDPORTS[0]} $K8S_user ${ETCDHOSTS[0]} "$command2run"
  grab_pki_ext_etcd_method $K8S_user ${ETCDHOSTS[0]} ${ETCDPORTS[0]}

  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    PREV_PWD=$(pwd)
    squawk 55 "push_pki_ext_etcd_method  $K8S_user ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}"
    push_pki_ext_etcd_method  $K8S_user ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
    cd $etcd_test_tmp/${HOST}
    squawk 55 "tar zcf - kubeadmcfg.yaml | ssh ${INIT_USER}@${HOST} cd /etc/kubernetes; tar pzxvf -"
    tar zcf - kubeadmcfg.yaml | ssh ${INIT_USER}@${HOST} "cd /etc/kubernetes; tar pzxvf -"
    cd $PREV_PWD
  done
  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
  done

  if [[ "$VERBOSITY" -ge "10" ]] ; then
    command2run="kubeadm init --dry-run --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-etcd.yaml,ExternalEtcdVersion --config /etc/kubernetes/kubeadmcfg.yaml"
    squawk 105 "$command2run"
    ssh ${INIT_USER}@${MASTERHOSTS[0]} "$command2run"
  fi
  for i in "${!MASTERHOSTS[@]}"; do
    HOST=${MASTERHOSTS[$i]}
    NAME=${MASTERNAMES[$i]}
    if [[ -e "$KUBASH_CLUSTER_DIR/master_join.sh" ]]; then
      rsync $KUBASH_RSYNC_OPTS "ssh -p ${MASTERPORTS[$i]}" $KUBASH_CLUSTER_DIR/master_join.sh $INIT_USER@$HOST:/tmp/
      push_kube_pki_ext_etcd_sub ${INIT_USER} ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
      my_KUBE_INIT="bash /tmp/master_join.sh"
      squawk 5 "kube init --> $my_KUBE_INIT"
      ssh -n -p ${MASTERPORTS[$i]} root@${HOST} "$my_KUBE_INIT" 2>&1 | tee $etcd_test_tmp/${HOST}-rawresults.k8s
      w8_node $my_node_name
    else
      my_KUBE_INIT="kubeadm init --config=/etc/kubernetes/kubeadmcfg.yaml"
      squawk 5 "master kube init --> $my_KUBE_INIT"
      my_grep='kubeadm join .* --token'
      ssh -n -p ${MASTERPORTS[$i]} root@${HOST} "$my_KUBE_INIT" 2>&1 | tee $etcd_test_tmp/${HOST}-rawresults.k8s
      run_join=$(cat $etcd_test_tmp/${HOST}-rawresults.k8s | grep -P -- "$my_grep")
      join_token=$(cat $etcd_test_tmp/${HOST}-rawresults.k8s \
        | grep -P -- "$my_grep" \
        | sed 's/\(.*\)--token\ \(\S*\)\ --discovery-token-ca-cert-hash\ .*/\2/')
      if [[ -z "$run_join" ]]; then
        horizontal_rule
        croak 3  'kubeadm init failed!'
      else
        echo $run_join > $KUBASH_CLUSTER_DIR/join.sh
        echo $run_join > $KUBASH_CLUSTER_DIR/master_join.sh
        sed -i 's/$/ --experimental-control-plane/' $KUBASH_CLUSTER_DIR/master_join.sh
        echo $join_token > $KUBASH_CLUSTER_DIR/join_token
        master_grab_kube_config ${NAME} ${HOST} ${INIT_USER} ${MASTERPORTS[$i]}
        grab_kube_pki_ext_etcd_sub ${INIT_USER} ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
        squawk 120 "rsync $KUBASH_RSYNC_OPTS ssh -p ${MASTERPORTS[$i]} $KUBASH_DIR/w8s/generic.w8 $INIT_USER@$HOST:/tmp/"
        rsync $KUBASH_RSYNC_OPTS "ssh -p ${MASTERPORTS[$i]}" $KUBASH_DIR/w8s/generic.w8 $INIT_USER@$HOST:/tmp/
        command2run='mv /tmp/generic.w8 /root/'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-proxy kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-apiserver kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-controller kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-scheduler kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${INIT_USER} ${MASTERHOSTS[$i]} "$command2run"
        sleep 11
        squawk 5 "do_net before other masters"
        w8_kubectl
        do_net
        w8_node $my_node_name
      fi
    fi
  done
  rm -Rf $etcd_test_tmp
}

etcd_kubernetes_docs_stacked_method () {
  etcd_kubernetes_13_docs_stacked_method
}

etcd_kubernetes_12_docs_stacked_method () {
  number_limiter=$1
  etcd_stacked_tmp=$(mktemp -d)
  STACKED_USER=root
  set_csv_columns
  etc_count_zero=0
  master_count_zero=0
  node_count_zero=0
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' || "$K8S_role" == 'primary_etcd' ]]; then
      ETCDHOSTS[$etc_count_zero]=$K8S_ip1
      ETCDNAMES[$etc_count_zero]=$K8S_node
      ETCDPORTS[$etc_count_zero]=$K8S_sshPort
      MASTERHOSTS[$master_count_zero]=$K8S_ip1
      MASTERNAMES[$master_count_zero]=$K8S_node
      MASTERPORTS[$master_count_zero]=$K8S_sshPort
      ((++etc_count_zero))
      ((++master_count_zero))
    elif [[ "$K8S_role" == 'node' ]]; then
      NODEHOSTS[$node_count_zero]=$K8S_ip1
      NODENAMES[$node_count_zero]=$K8S_node
      NODEPORTS[$node_count_zero]=$K8S_sshPort
      ((++node_count_zero))
    fi
  done <<< "$kubash_hosts_csv_slurped"
  echo $ETCDHOSTS
  sleep 33
  get_major_minor_kube_version $K8S_user ${MASTERHOSTS[0]} ${MASTERNAMES[0]} ${MASTERPORTS[0]}
  determine_api_version

  echo -n '            initial-cluster: "' > $etcd_stacked_tmp/initial-cluster.head
  if [[ "$ETCD_TLS" == 'true' ]]; then
    echo -n '            listen-client-urls: "https://127.0.0.1:2379,' > $etcd_stacked_tmp/listen-client_urls.head
  else
    echo -n '            listen-client-urls: "https://127.0.0.1:2379,' > $etcd_stacked_tmp/listen-client_urls.head
  fi
  count_etcd=0
  countetcdnodes=0
  while IFS="," read -r $csv_columns
  do
    echo "- \"${K8S_ip1}\"" >> $etcd_stacked_tmp/apiservercertsans.line
    if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' || "$K8S_role" == 'primary_etcd' ]]; then
      if [[ $countetcdnodes -gt 0 ]]; then
        printf ',' >> $etcd_stacked_tmp/initial-cluster.line
        printf ',' >> $etcd_stacked_tmp/listen-client_urls.line
      fi
      if [[ "$ETCD_TLS" == 'true' ]]; then
        echo "      - https://${K8S_ip1}:2379" >> $etcd_stacked_tmp/endpoints.line
        printf "${K8S_node}=https://${K8S_ip1}:2380" >>  $etcd_stacked_tmp/initial-cluster.line
        printf "https://${K8S_ip1}:2379" > $etcd_stacked_tmp/${countetcdnodes}-listen-client_urls.line
      else
        echo "      - https://${K8S_ip1}:2379" >> $etcd_stacked_tmp/endpoints.line
        printf "${K8S_node}=https://${K8S_ip1}:2380" >>  $etcd_stacked_tmp/initial-cluster.line
        printf "https://${K8S_ip1}:2379" > $etcd_stacked_tmp/${countetcdnodes}-listen-client_urls.line
      fi
      cp $etcd_stacked_tmp/initial-cluster.line $etcd_stacked_tmp/${countetcdnodes}-initial-cluster.line
      printf '"' >> $etcd_stacked_tmp/${countetcdnodes}-initial-cluster.line
      printf " \n" >> $etcd_stacked_tmp/${countetcdnodes}-initial-cluster.line
      printf '"' >> $etcd_stacked_tmp/${countetcdnodes}-listen-client_urls.line
      printf " \n" >> $etcd_stacked_tmp/${countetcdnodes}-listen-client_urls.line
      ((++countetcdnodes))
    fi
    ((++count_etcd))
  done <<< "$kubash_hosts_csv_slurped"
  printf '"' >> $etcd_stacked_tmp/initial-cluster.line
  printf '"' >> $etcd_stacked_tmp/listen-client_urls.line
  printf " \n" >> $etcd_stacked_tmp/initial-cluster.line
  printf " \n" >> $etcd_stacked_tmp/listen-client_urls.line

  initial_cluster_line=$(cat $etcd_stacked_tmp/initial-cluster.head $etcd_stacked_tmp/initial-cluster.line)
  api_server_cert_sans_line=$(cat $etcd_stacked_tmp/apiservercertsans.line)
  endpoints_line=$(cat $etcd_stacked_tmp/endpoints.line)

  for i in "${!MASTERHOSTS[@]}"; do
    initial_cluster_line=$(cat $etcd_stacked_tmp/initial-cluster.head $etcd_stacked_tmp/${i}-initial-cluster.line)
    listen_client_urls_line=$(cat $etcd_stacked_tmp/listen-client_urls.head $etcd_stacked_tmp/${i}-listen-client_urls.line)
    api_server_cert_sans_line=$(cat $etcd_stacked_tmp/apiservercertsans.line)
    endpoints_line=$(cat $etcd_stacked_tmp/endpoints.line)
    HOST=${MASTERHOSTS[$i]}
    NAME=${MASTERNAMES[$i]}
    mkdir -p $etcd_stacked_tmp/${HOST}
    if [ "$i" -eq '0' ]; then
      INITIAL_CLUSTER_STATE=new
    else
      INITIAL_CLUSTER_STATE=existing
    fi
    cat << EOF > $etcd_stacked_tmp/${HOST}/kubeadmcfg.yaml
apiVersion: $kubeadm_apiVersion
kind: $kubeadm_cfg_kind
apiServerCertSANs:
- "127.0.0.1"
$api_server_cert_sans_line
controlPlaneEndpoint: "${MASTERHOSTS[0]}:6443"
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        - "${NAME}"
        peerCertSANs:
        - "${HOST}"
        - "${NAME}"
        extraArgs:
$listen_client_urls_line
            advertise-client-urls: "https://${HOST}:2379"
            listen-peer-urls: "https://${HOST}:2380"
            initial-advertise-peer-urls: "https://${HOST}:2380"
$initial_cluster_line
            initial-cluster-state: $INITIAL_CLUSTER_STATE
networking:
  podSubnet: $my_KUBE_CIDR
EOF
    squawk 55 "push_pki_ext_etcd_method  $K8S_SU_STACKED_USER ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}"
    rsync $KUBASH_RSYNC_OPTS "ssh -p ${MASTERPORTS[$i]}" $etcd_stacked_tmp/${HOST}/kubeadmcfg.yaml $STACKED_USER@$HOST:/tmp/
    command2run='mv /tmp/kubeadmcfg.yaml /etc/kubernetes/'
    sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"

    if [[ -e "$KUBASH_CLUSTER_DIR/join.sh" ]]; then
      rsync $KUBASH_RSYNC_OPTS "ssh -p ${MASTERPORTS[$i]}" $KUBASH_DIR/templates/kube_stacked_init.sh $STACKED_USER@$HOST:/tmp/
      squawk 55 "push_kube_pki_stacked_method  $K8S_user ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}"
      push_kube_pki_stacked_method ${STACKED_USER} ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
      command2run="ls -Rl /etc/kubernetes"
      sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"
      command2run="rm -fv /etc/kubernetes/kubelet.conf"
      sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"
      escaped_master=$( echo ${MASTERHOSTS[0]} |sed 's/\./\\./g')
      sedder="s/$escaped_master/$HOST/g"
      command2run='mv /tmp/kube_stacked_init.sh /etc/kubernetes/'
      sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"
      my_KUBE_INIT="bash /etc/kubernetes/kube_stacked_init.sh ${MASTERHOSTS[0]} ${MASTERNAMES[0]} ${MASTERHOSTS[$i]} ${MASTERNAMES[$i]}"
      squawk 5 "kube init --> $my_KUBE_INIT"
      ssh -n -p ${MASTERPORTS[$i]} root@${HOST} "$my_KUBE_INIT" 2>&1 | tee $etcd_stacked_tmp/${HOST}-rawresults.k8s
    else
      my_KUBE_INIT="kubeadm init --config=/etc/kubernetes/kubeadmcfg.yaml"
      squawk 5 "master kube init --> $my_KUBE_INIT"
      my_grep='kubeadm join .* --token'
      ssh -n -p ${MASTERPORTS[$i]} root@${HOST} "$my_KUBE_INIT" 2>&1 | tee $etcd_stacked_tmp/${HOST}-rawresults.k8s
      run_join=$(cat $etcd_stacked_tmp/${HOST}-rawresults.k8s | grep -P -- "$my_grep")
      join_token=$(cat $etcd_stacked_tmp/${HOST}-rawresults.k8s \
        | grep -P -- "$my_grep" \
        | sed 's/\(.*\)--token\ \(\S*\)\ --discovery-token-ca-cert-hash\ .*/\2/')
      if [[ -z "$run_join" ]]; then
        horizontal_rule
        croak 3  'kubeadm init failed!'
      else
        echo $run_join > $KUBASH_CLUSTER_DIR/join.sh
        echo $join_token > $KUBASH_CLUSTER_DIR/join_token
        master_grab_kube_config ${NAME} ${HOST} ${STACKED_USER} ${MASTERPORTS[$i]}
        grab_kube_pki_stacked_method ${STACKED_USER} ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
        squawk 120 "rsync $KUBASH_RSYNC_OPTS ssh -p ${MASTERPORTS[$i]} $KUBASH_DIR/w8s/generic.w8 $STACKED_USER@$HOST:/tmp/"
        rsync $KUBASH_RSYNC_OPTS "ssh -p ${MASTERPORTS[$i]}" $KUBASH_DIR/w8s/generic.w8 $STACKED_USER@$HOST:/tmp/
        command2run='mv /tmp/generic.w8 /root/'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-controller kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-scheduler kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-apiserver kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"
        squawk 5 "do_net before other masters"
        w8_kubectl
        do_net
        w8_node $my_node_name
      fi
    fi
  done
  squawk 55 'key nodes'
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == 'node' ]]; then
      squawk 165 'nodes will have certs created by the join command'
    fi
  done <<< "$kubash_hosts_csv_slurped"
  rm -Rf $etcd_stacked_tmp

}

etcd_kubernetes_13_docs_stacked_method () {
  number_limiter=$1
  etcd_stacked_tmp=$(mktemp -d)
  STACKED_USER=root
  set_csv_columns
  etc_count_zero=0
  master_count_zero=0
  node_count_zero=0
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == 'etcd' || "$K8S_role" == 'master' || "$K8S_role" == 'primary_master' || "$K8S_role" == 'primary_etcd' ]]; then
      ETCDHOSTS[$etc_count_zero]=$K8S_ip1
      ETCDNAMES[$etc_count_zero]=$K8S_node
      ETCDPORTS[$etc_count_zero]=$K8S_sshPort
      MASTERHOSTS[$master_count_zero]=$K8S_ip1
      MASTERNAMES[$master_count_zero]=$K8S_node
      MASTERPORTS[$master_count_zero]=$K8S_sshPort
      ((++etc_count_zero))
      ((++master_count_zero))
    elif [[ "$K8S_role" == 'node' ]]; then
      NODEHOSTS[$node_count_zero]=$K8S_ip1
      NODENAMES[$node_count_zero]=$K8S_node
      NODEPORTS[$node_count_zero]=$K8S_sshPort
      ((++node_count_zero))
    fi
  done <<< "$kubash_hosts_csv_slurped"
  get_major_minor_kube_version $K8S_user ${MASTERHOSTS[0]} ${MASTERNAMES[0]} ${MASTERPORTS[0]}
  determine_api_version

  count_etcd=0
  while IFS="," read -r $csv_columns
  do
    echo "${TAB_1}- \"${K8S_ip1}\"" >> $etcd_stacked_tmp/apiservercertsans.line
    ((++count_etcd))
  done <<< "$kubash_hosts_csv_slurped"

  api_server_cert_sans_line=$(cat $etcd_stacked_tmp/apiservercertsans.line)

  for i in "${!MASTERHOSTS[@]}"; do
    squawk 35 "master-loop ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}"
    api_server_cert_sans_line=$(cat $etcd_stacked_tmp/apiservercertsans.line)
    HOST=${MASTERHOSTS[$i]}
    NAME=${MASTERNAMES[$i]}
    mkdir -p $etcd_stacked_tmp/${HOST}
    if [ "$i" -eq '0' ]; then
      INITIAL_CLUSTER_STATE=new
    else
      INITIAL_CLUSTER_STATE=existing
    fi
    cat << EOF > $etcd_stacked_tmp/${HOST}/kubeadmcfg.yaml
apiVersion: $kubeadm_apiVersion
kind: $kubeadm_cfg_kind
kubernetesVersion: stable
apiServer:
  certSANs:
  - "127.0.0.1"
$api_server_cert_sans_line
controlPlaneEndpoint: "${MASTERHOSTS[0]}:6443"
networking:
  podSubnet: $my_KUBE_CIDR
EOF
    squawk 55 "push_pki_ext_etcd_method  $K8S_SU_STACKED_USER ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}"
    rsync $KUBASH_RSYNC_OPTS "ssh -p ${MASTERPORTS[$i]}" $etcd_stacked_tmp/${HOST}/kubeadmcfg.yaml $STACKED_USER@$HOST:/tmp/
    command2run='mv /tmp/kubeadmcfg.yaml /etc/kubernetes/'
    sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"

    if [[ -e "$KUBASH_CLUSTER_DIR/master_join.sh" ]]; then
      rsync $KUBASH_RSYNC_OPTS "ssh -p ${MASTERPORTS[$i]}" $KUBASH_CLUSTER_DIR/master_join.sh $STACKED_USER@$HOST:/tmp/
      squawk 55 "push_kube_pki_stacked_method  $K8S_user ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}"
      push_kube_pki_stacked_method ${STACKED_USER} ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
      my_KUBE_INIT="bash /tmp/master_join.sh"
      squawk 5 "kube init --> $my_KUBE_INIT"
      ssh -n -p ${MASTERPORTS[$i]} root@${HOST} "$my_KUBE_INIT" 2>&1 | tee $etcd_stacked_tmp/${HOST}-rawresults.k8s
      w8_node $my_node_name
    else
      my_KUBE_INIT="kubeadm init --config=/etc/kubernetes/kubeadmcfg.yaml"
      squawk 5 "master kube init --> $my_KUBE_INIT"
      my_grep='kubeadm join .* --token'
      ssh -n -p ${MASTERPORTS[$i]} root@${HOST} "$my_KUBE_INIT" 2>&1 | tee $etcd_stacked_tmp/${HOST}-rawresults.k8s
      run_join=$(cat $etcd_stacked_tmp/${HOST}-rawresults.k8s | grep -P -- "$my_grep")
      join_token=$(cat $etcd_stacked_tmp/${HOST}-rawresults.k8s \
        | grep -P -- "$my_grep" \
        | sed 's/\(.*\)--token\ \(\S*\)\ --discovery-token-ca-cert-hash\ .*/\2/')
      if [[ -z "$run_join" ]]; then
        horizontal_rule
        croak 3  'kubeadm init failed!'
      else
        echo $run_join > $KUBASH_CLUSTER_DIR/join.sh
        echo $run_join > $KUBASH_CLUSTER_DIR/master_join.sh
        sed -i 's/$/ --experimental-control-plane/' $KUBASH_CLUSTER_DIR/master_join.sh
        echo $join_token > $KUBASH_CLUSTER_DIR/join_token
        master_grab_kube_config ${NAME} ${HOST} ${STACKED_USER} ${MASTERPORTS[$i]}
        grab_kube_pki_stacked_method ${STACKED_USER} ${MASTERHOSTS[$i]} ${MASTERPORTS[$i]}
        squawk 120 "rsync $KUBASH_RSYNC_OPTS ssh -p ${MASTERPORTS[$i]} $KUBASH_DIR/w8s/generic.w8 $STACKED_USER@$HOST:/tmp/"
        rsync $KUBASH_RSYNC_OPTS "ssh -p ${MASTERPORTS[$i]}" $KUBASH_DIR/w8s/generic.w8 $STACKED_USER@$HOST:/tmp/
        command2run='mv /tmp/generic.w8 /root/'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-controller kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-scheduler kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"
        command2run='/root/generic.w8 kube-apiserver kube-system'
        squawk 155 "$command2run"
        sudo_command ${MASTERPORTS[$i]} ${STACKED_USER} ${MASTERHOSTS[$i]} "$command2run"
        squawk 5 "do_net before other masters"
        w8_kubectl
        do_net
        w8_node $my_node_name
      fi
    fi
  done
  squawk 55 'key nodes'
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == 'node' ]]; then
      squawk 165 'nodes will have certs created by the join command'
    fi
  done <<< "$kubash_hosts_csv_slurped"
  rm -Rf $etcd_stacked_tmp
}

scanner () {
  squawk 17 "scanner $@"
  node_ip=$1
  node_port=$2
  removestalekeys $node_ip
  ssh-keyscan -p $node_port $node_ip >> ~/.ssh/known_hosts
}

scanlooper () {
  squawk 5 "scanlooper"
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    scanner $K8S_ip1 $K8S_sshPort
  done <<< "$kubash_hosts_csv_slurped"
}

ntpsync_in_parallel () {
  squawk 2 'syncing ntp on all hosts'
  ntp_sync_tmp_para=$(mktemp -d --suffix='.para.tmp')
  set_csv_columns
  while IFS="," read -r $csv_columns
  do
    squawk 103 "ntp sync $K8S_user@$K8S_ip1"
    MY_NTP_SYNC="timedatectl set-ntp true"
    squawk 5 "ssh -n -p $K8S_sshPort $K8S_provisionerUser@$K8S_ip1 \"$MY_NTP_SYNC\""
    echo "ssh -n -p $K8S_sshPort $K8S_provisionerUser@$K8S_ip1 \"$MY_NTP_SYNC\""\
        >> $ntp_sync_tmp_para/hopper
  done < $KUBASH_HOSTS_CSV
  while IFS="," read -r $csv_columns
  do
    squawk 103 "ntp sync $K8S_user@$K8S_ip1"
    MY_NTP_SYNC="timedatectl status "
    squawk 5 "ssh -n -p $K8S_sshPort $K8S_provisionerUser@$K8S_ip1 \"$MY_NTP_SYNC\""
    echo "ssh -n -p $K8S_sshPort $K8S_provisionerUser@$K8S_ip1 \"$MY_NTP_SYNC\""\
        >> $ntp_sync_tmp_para/hopper2
  done < $KUBASH_HOSTS_CSV
  while IFS="," read -r $csv_columns
  do
    squawk 103 "ntp sync $K8S_user@$K8S_ip1"
    MY_NTP_SYNC="date"
    squawk 5 "ssh -n -p $K8S_sshPort $K8S_provisionerUser@$K8S_ip1 \"$MY_NTP_SYNC\""
    echo "ssh -n -p $K8S_sshPort $K8S_provisionerUser@$K8S_ip1 \"$MY_NTP_SYNC\""\
        >> $ntp_sync_tmp_para/hopper3
  done < $KUBASH_HOSTS_CSV

  if [[ "$VERBOSITY" -gt "9" ]] ; then
    cat $ntp_sync_tmp_para/hopper
  fi
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    $PARALLEL  -j $PARALLEL_JOBS -- < $ntp_sync_tmp_para/hopper
    $PARALLEL  -j $PARALLEL_JOBS -- < $ntp_sync_tmp_para/hopper2
    $PARALLEL  -j $PARALLEL_JOBS -- < $ntp_sync_tmp_para/hopper3
  else
    bash $ntp_sync_tmp_para/hopper
    bash $ntp_sync_tmp_para/hopper2
    bash $ntp_sync_tmp_para/hopper3
  fi
  rm -Rf $ntp_sync_tmp_para
}

process_hosts_csv () {
  squawk 3 " process_hosts_csv"
  ntpsync_in_parallel
  while IFS="," read -r $csv_columns
  do
    if [[ "$K8S_role" == "primary_master" ]]; then
      get_major_minor_kube_version $K8S_user $K8S_ip1  $K8S_node $K8S_sshPort
    fi
  done <<< "$kubash_hosts_csv_slurped"
  if [[ $KUBE_MAJOR_VER -eq 1 ]]; then
    squawk 101 'Major Version 1'
    squawk 53  "$KUBE_MAJOR_VER.$KUBE_MINOR_VER supported"
    if [[ $KUBE_MINOR_VER -eq 12 ]]; then
      if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
        etcd_kubernetes_12_docs_stacked_method
      else
        etcd_kubernetes_12_ext_etcd_method
      fi
    elif [[ $KUBE_MINOR_VER -eq 13 ]]; then
      if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
        etcd_kubernetes_13_docs_stacked_method
      else
        etcd_kubernetes_13_ext_etcd_method
      fi
    else
      if [[ "$MASTERS_AS_ETCD" == "true" ]]; then
        etcd_kubernetes_docs_stacked_method
      else
        etcd_kubernetes_ext_etcd_method
      fi
    fi
  elif [[ $MAJOR_VER -eq 2 ]]; then
      croak 3  "$KUBE_MAJOR_VER.$KUBE_MINOR_VER not supported at this time"
  else
    croak 3  "$KUBE_MAJOR_VER.$KUBE_MINOR_VER not supported at this time"
  fi
  # spin up nodes
  if [[ "$PARALLEL_JOBS" -gt "1" ]] ; then
    do_nodes_in_parallel
  else
    do_nodes
  fi
}

initialize () {
  squawk 1 " initialize"
  check_csv
  if [[ -z "$kubash_hosts_csv_slurped" ]]; then
    hosts_csv_slurp
  fi
  scanlooper
  check_coreos
  process_hosts_csv
}

kubeadm2ha_initialize () {
  squawk 1 "kubeadm2ha initialize"
  check_csv
  if [[ -e "$KUBASH_ANSIBLE_HOSTS" ]]; then
    squawk 1 'Hosts file found, not overwriting'
  else
    write_ansible_kubeadm2ha_hosts
  fi
  ansible-playbook \
    -f $PARALLEL_JOBS \
    -i $KUBASH_ANSIBLE_HOSTS \
    $KUBASH_DIR/submodules/kubeadm2ha/ansible/cluster-setup.yaml
  ansible-playbook \
    -f $PARALLEL_JOBS \
    -i $KUBASH_ANSIBLE_HOSTS \
    $KUBASH_DIR/submodules/kubeadm2ha/ansible/cluster-dashboard.yaml
  ansible-playbook \
    -f $PARALLEL_JOBS \
    -i $KUBASH_ANSIBLE_HOSTS \
    $KUBASH_DIR/submodules/kubeadm2ha/ansible/cluster-load-balanced.yaml
  ansible-playbook \
    -f $PARALLEL_JOBS \
    -i $KUBASH_ANSIBLE_HOSTS \
    $KUBASH_DIR/submodules/kubeadm2ha/ansible/etcd-operator.yaml
  ansible-playbook \
    -f $PARALLEL_JOBS \
    -i $KUBASH_ANSIBLE_HOSTS \
    $KUBASH_DIR/submodules/kubeadm2ha/ansible/local-access.yaml
}

kubespray_initialize () {
  squawk 1 "kubespray initialize"
  check_csv
  if [[ -e "$KUBASH_KUBESPRAY_HOSTS" ]]; then
    squawk 1 'Hosts file found, not overwriting'
  else
    write_ansible_kubespray_hosts
  fi
  #yes yes|ansible-playbook \
    #-i $KUBASH_KUBESPRAY_HOSTS \
    #-e kube_version=$KUBE_VERSION \
    #$KUBASH_DIR/submodules/kubespray/reset.yml
  ansible-playbook \
    -i $KUBASH_KUBESPRAY_HOSTS \
    -e '{ kubeadm_enabled: True }' \
    $KUBASH_DIR/submodules/kubespray/cluster.yml
}

openshift_initialize () {
  squawk 1 "openshift initialize"
  check_csv
  if [[ -e "$KUBASH_ANSIBLE_HOSTS" ]]; then
    squawk 1 'Hosts file found, not overwriting'
  else
    write_ansible_openshift_hosts
  fi
  ansible-playbook \
    -i $KUBASH_ANSIBLE_HOSTS \
    $KUBASH_DIR/submodules/openshift-ansible/playbooks/prerequisites.yml
  ansible-playbook \
    -i $KUBASH_ANSIBLE_HOSTS \
    $KUBASH_DIR/submodules/openshift-ansible/playbooks/deploy_cluster.yml
}

do_coreos_initialization () {
  CNI_VERSION="v0.6.0"
  RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
  CORETMP=$KUBASH_DIR/tmp
  cd $CORETMP

  do_command_in_parallel_on_os 'coreos' "mkdir -p /opt/cni/bin"
  wget -c "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-amd64-${CNI_VERSION}.tgz"
  copy_in_parallel_to_os "coreos" $CORETMP/cni-plugins-amd64-${CNI_VERSION}.tgz /tmp/
  #rm $CORETMP/cni-plugins-amd64-${CNI_VERSION}.tgz
  do_command_in_parallel_on_os "coreos" "tar -C /opt/cni/bin -xzf /tmp/cni-plugins-amd64-${CNI_VERSION}.tgz"
  do_command_in_parallel_on_os "coreos" "rm -f /tmp/cni-plugins-amd64-${CNI_VERSION}.tgz"

  do_command_in_parallel_on_os "coreos" "mkdir -p /opt/bin"

  if [[ -e "$CORETMP/kubelet" ]]; then
    squawk 9 "kubelet has no headers and will not continue skipping for now"
  else
    wget -c https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}
  fi
  # cd /opt/bin
  copy_in_parallel_to_os "coreos" $CORETMP/kubeadm /tmp/
  do_command_in_parallel_on_os "coreos" "mv /tmp/kubeadm /opt/bin/"
  #rm $CORETMP/kubeadm
  copy_in_parallel_to_os "coreos" $CORETMP/kubelet /tmp/
  do_command_in_parallel_on_os "coreos" "mv /tmp/kubelet /opt/bin/"
  #rm $CORETMP/kubelet
  copy_in_parallel_to_os "coreos" $CORETMP/kubectl /tmp/
  do_command_in_parallel_on_os "coreos" "mv /tmp/kubectl /opt/bin/"
  #rm $CORETMP/kubectl
  do_command_in_parallel_on_os "coreos" "cd /opt/bin; chmod +x {kubeadm,kubelet,kubectl}"

  if [[ -e "$CORETMP/kubelet.service" ]]; then
    squawk 9 "already retrieved"
  else
    wget -c "https://raw.githubusercontent.com/kubernetes/kubernetes/${RELEASE}/build/debs/kubelet.service"
    sed -i 's:/usr/bin:/opt/bin:g' $CORETMP/kubelet.service
  fi
  copy_in_parallel_to_os "coreos" $CORETMP/kubelet.service /tmp/kubelet.service
  do_command_in_parallel_on_os "coreos" "mv /tmp/kubelet.service /etc/systemd/system/kubelet.service"
  rm $CORETMP/kubelet.service
  do_command_in_parallel_on_os "coreos" "mkdir -p /etc/systemd/system/kubelet.service.d"
  if [[ -e "$CORETMP/10-kubeadm.conf" ]]; then
    squawk 9 "already retrieved"
  else
    wget -c "https://raw.githubusercontent.com/kubernetes/kubernetes/${RELEASE}/build/debs/10-kubeadm.conf"
    sed -i 's:/usr/bin:/opt/bin:g' $CORETMP/10-kubeadm.conf
  fi
  copy_in_parallel_to_os "coreos" $CORETMP/10-kubeadm.conf /tmp/10-kubeadm.conf
  do_command_in_parallel_on_os "coreos" " mv /tmp/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
  rm $CORETMP/10-kubeadm.conf

  do_command_in_parallel_on_os "coreos" " systemctl restart docker.service ; systemctl enable docker.service"

  #do_command_in_parallel_on_os "coreos" "systemctl unmask kubelet.service ; systemctl restart kubelet.service ; systemctl enable kubelet.service"
  do_command_in_parallel_on_os "coreos" "systemctl restart kubelet.service ; systemctl enable kubelet.service"

  #rmdir $CORETMP
}
