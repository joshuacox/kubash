#!/bin/bash -l
. .ci/header
. ~/.bashrc
echo builder.sh

cleanup () {
  kubash -n coreos1 decommission -y 
  rm -Rf ~/.kubash/clusters/coreos1
}

main () {
  set -eux
  kubash -n coreos1 yaml2cluster ~/.kubash/examples/coreos1-stacked.yaml
  kubash -n coreos1 provision --verbosity=100
  kubash -n coreos1 init --verbosity=100
  cp ~/.kubash/clusters/coreos1/config ~/.kube/config
  date -I > $THIS_CLUSTER_NAME.log
  kubectl get nodes >> coreos1.log
  kubectl get pods --all-namespaces >> coreos1.log
  cd ~/.kubash
  bats .ci/.tests.bats
  cleanup
}

cleanup
time main $@
