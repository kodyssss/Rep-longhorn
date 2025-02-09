#!/bin/bash

# 获取第一个节点的名称
CLUSTER_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

# 获取 API 服务器地址
API_SERVER=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# 配置变量
USERNAME="demo4-${CLUSTER_NAME}"
NAMESPACE="default"
PERMISSION_LEVEL="cluster-readonly"  # 可选 namespace 或 cluster-readonly
CA_CERT_PATH="/var/lib/rancher/rke2/server/tls/server-ca.crt"  # 指定CA证书路径

# 生成证书
openssl genrsa -out ${USERNAME}.key 2048
openssl req -new -key ${USERNAME}.key -out ${USERNAME}.csr -subj "/CN=${USERNAME}/O=my-group"

# 提交并批准 CSR
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USERNAME}-csr
spec:
  request: $(cat ${USERNAME}.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
  - client auth
EOF

kubectl certificate approve ${USERNAME}-csr

# 等待CSR被批准并获取证书
while true; do
  CERT=$(kubectl get csr ${USERNAME}-csr -o jsonpath='{.status.certificate}')
  if [[ -n "$CERT" ]]; then
    echo "$CERT" | base64 -d > ${USERNAME}.crt
    break
  fi
  echo "等待CSR批准..."
  sleep 2
done

# 创建 RBAC 权限
if [ "$PERMISSION_LEVEL" == "namespace" ]; then
  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ${NAMESPACE}
  name: ${USERNAME}-role
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "jobs", "services"]
  verbs: ["get", "list", "watch", "create", "update", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${USERNAME}-role-binding
  namespace: ${NAMESPACE}
subjects:
- kind: User
  name: ${USERNAME}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ${USERNAME}-role
  apiGroup: rbac.authorization.k8s.io
EOF
else
  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ${USERNAME}-readonly
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${USERNAME}-readonly-binding
subjects:
- kind: User
  name: ${USERNAME}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: ${USERNAME}-readonly
  apiGroup: rbac.authorization.k8s.io
EOF
fi

# 生成 kubeconfig
kubectl config set-cluster ${CLUSTER_NAME} \
  --server=https://${API_SERVER}:6443 \
  --certificate-authority=${CA_CERT_PATH} \
  --embed-certs=true \
  --kubeconfig=${USERNAME}.kubeconfig

kubectl config set-credentials ${USERNAME} \
  --client-certificate=${USERNAME}.crt \
  --client-key=${USERNAME}.key \
  --embed-certs=true \
  --kubeconfig=${USERNAME}.kubeconfig

kubectl config set-context ${USERNAME}-context \
  --cluster=${CLUSTER_NAME} \
  --user=${USERNAME} \
  --namespace=${NAMESPACE} \
  --kubeconfig=${USERNAME}.kubeconfig

kubectl config use-context ${USERNAME}-context \
  --kubeconfig=${USERNAME}.kubeconfig

echo "完成！用户 ${USERNAME} 的 kubeconfig 文件: ${USERNAME}.kubeconfig"
