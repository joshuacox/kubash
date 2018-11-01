#!/bin/bash

# Update HOST0, HOST1, and HOST2 with the IPs or resolvable names of your hosts
export HOST0=10.0.0.6
export HOST1=10.0.0.7
export HOST2=10.0.0.8
USER=root

cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --address=127.0.0.1 --pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true
Restart=always
EOF

systemctl daemon-reload
systemctl restart kubelet

# Create temp directories to store files that will end up on other hosts.
mkdir -p /tmp/${HOST0}/ /tmp/${HOST1}/ /tmp/${HOST2}/

ETCDHOSTS=(${HOST0} ${HOST1} ${HOST2})
NAMES=("infra0" "infra1" "infra2")

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
cp -R /etc/kubernetes/pki /tmp/${HOST0}/

kubeadm alpha phase certs etcd-server --config=/tmp/${HOST2}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-peer --config=/tmp/${HOST2}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-healthcheck-client --config=/tmp/${HOST2}/kubeadmcfg.yaml
kubeadm alpha phase certs apiserver-etcd-client --config=/tmp/${HOST2}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${HOST2}/
# cleanup non-reusable certificates
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm alpha phase certs etcd-server --config=/tmp/${HOST1}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-peer --config=/tmp/${HOST1}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-healthcheck-client --config=/tmp/${HOST1}/kubeadmcfg.yaml
kubeadm alpha phase certs apiserver-etcd-client --config=/tmp/${HOST1}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${HOST1}/
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm alpha phase certs etcd-server --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-peer --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-healthcheck-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm alpha phase certs apiserver-etcd-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
# No need to move the certs because they are for HOST0

# clean up certs that should not be copied off this host
find /tmp/${HOST2} -name ca.key -type f -delete
find /tmp/${HOST1} -name ca.key -type f -delete

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

ssh ${USER}@${HOST0} "$command2run"
