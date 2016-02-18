#!/bin/sh

KUBERNETES_RELEASE=v1.1.7
URL=https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_RELEASE}/bin/linux/amd64

wget -nc -nd -nv \
  ${URL}/kube-apiserver \
  ${URL}/kube-controller-manager \
  ${URL}/kube-proxy \
  ${URL}/kube-scheduler \
  ${URL}/kubelet

cat >wupiao <<EOF
#!/bin/bash
# [w]ait [u]ntil [p]ort [i]s [a]ctually [o]pen
[ -n "$1" ] && \
  until curl -o /dev/null -sIf http://${1}; do \
    sleep 1 && echo .;
  done;
exit $?
EOF
