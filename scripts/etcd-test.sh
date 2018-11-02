#!/bin/bash
USER=root
# check and ensure that args were given
if [ $# -eq 0 ]; then
  # Print usage
  echo 'Error! no arguments'
  echo 'usage:'
  echo "$0 host0 host1 host2"
  exit 1
fi

ETCDHOSTS=($@)

#ETCDHOSTS=(${HOST0} ${HOST1} ${HOST2})
for i in "${!ETCDHOSTS[@]}"; do
  HOST=${ETCDHOSTS[$i]}
  #NAMES=("infra0" "infra1" "infra2")
  THIS_NAMES="infra${i} ${THIS_NAMES}"
  # Create temp directories to store files that will end up on other hosts.
  echo mkdir -p /tmp/${HOST}/
  mkdir -p /tmp/${HOST}/

  # break indentation
  command2run='cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --address=127.0.0.1 --pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true
Restart=always
EOF'
  # unbreak indentation

  echo "ssh ${USER}@${HOST} $command2run"
  ssh ${USER}@${HOST} "$command2run"
  command2run='systemctl daemon-reload'
  echo "ssh ${USER}@${HOST} $command2run"
  ssh ${USER}@${HOST} "$command2run"
  command2run='systemctl restart kubelet'
  echo "ssh ${USER}@${HOST} $command2run"
  ssh ${USER}@${HOST} "$command2run"
done
NAMES=("${THIS_NAMES}")

for i in "${!ETCDHOSTS[@]}"; do
  HOST=${ETCDHOSTS[$i]}
  NAME=${NAMES[$i]}
  cat << EOF > /tmp/${HOST}/kubeadmcfg.yaml
apiVersion: "kubeadm.k8s.io/v1alpha3"
kind: ClusterConfiguration
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
            initial-cluster: infra0=https://${ETCDHOSTS[0]}:2380,infra1=https://${ETCDHOSTS[1]}:2380,infra2=https://${ETCDHOSTS[2]}:2380
            initial-cluster-state: new
            name: ${NAME}
            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380
EOF
done

kubeadm alpha phase certs etcd-ca

# host 0
cp -R /etc/kubernetes/pki /tmp/${ETCDHOSTS[0]}/

for i in "${!ETCDHOSTS[@]}"; do
  HOST=${ETCDHOSTS[$i]}
  kubeadm alpha phase certs etcd-server --config=/tmp/${HOST}/kubeadmcfg.yaml
  kubeadm alpha phase certs etcd-peer --config=/tmp/${HOST}/kubeadmcfg.yaml
  kubeadm alpha phase certs etcd-healthcheck-client --config=/tmp/${HOST}/kubeadmcfg.yaml
  kubeadm alpha phase certs apiserver-etcd-client --config=/tmp/${HOST}/kubeadmcfg.yaml
  rsync -a /etc/kubernetes/pki /tmp/${HOST}/
  # cleanup non-reusable certificates
  find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete
  # clean up certs that should not be copied off this host
  find /tmp/${HOST} -name ca.key -type f -delete
done

for i in "${!ETCDHOSTS[@]}"; do
  HOST=${ETCDHOSTS[$i]}
  echo "scp -r /tmp/${HOST}/* ${USER}@${HOST}:"
  scp -r /tmp/${HOST}/* ${USER}@${HOST}:
  echo "ssh ${USER}@${HOST} sudo chown -R root:root pki"
  ssh ${USER}@${HOST} "sudo chown -R root:root pki"
  #ssh ${USER}@${HOST} "sudo mv -f pki /etc/kubernetes/"
  echo "ssh ${USER}@${HOST} sudo rsync -a pki /etc/kubernetes/"
  ssh ${USER}@${HOST} "sudo rsync -a pki /etc/kubernetes/"
  echo "ssh ${USER}@${HOST} kubeadm alpha phase etcd local --config=/root/kubeadmcfg.yaml"
  ssh ${USER}@${HOST} "kubeadm alpha phase etcd local --config=/root/kubeadmcfg.yaml"
done

command2run="docker run --rm  \
  --net host \
  -v /etc/kubernetes:/etc/kubernetes quay.io/coreos/etcd:v3.2.18 etcdctl \
  --cert-file /etc/kubernetes/pki/etcd/peer.crt \
  --key-file /etc/kubernetes/pki/etcd/peer.key \
  --ca-file /etc/kubernetes/pki/etcd/ca.crt \
  --endpoints https://${HOST0}:2379 cluster-health"

ssh ${USER}@${ETCDHOSTS[0]} "$command2run"
