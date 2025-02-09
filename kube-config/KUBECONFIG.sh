#!/bin/bash

# 设置kubeconfig文件的源目录
SRC_DIR="/root/Rep-longhorn/kube-config"

# 设置具体的kubeconfig文件名称
CONFIG1="demo4-beijing-rep.kubeconfig"
CONFIG2="demo4-shanghai-produ.kubeconfig"

# 设置KUBECONFIG环境变量，包含多个配置文件
KUBECONFIG=~/.kube/config:$SRC_DIR/$CONFIG1:$SRC_DIR/$CONFIG2

# 目标目录
TARGET_DIR="/root/Rep-longhorn/kube-config"
TARGET_FILE="$TARGET_DIR/config"

# 合并并展平配置文件，输出到目标目录
kubectl config view --merge --flatten > "$TARGET_FILE"


echo "合并后的配置文件已保存到: $TARGET_FILE"
echo "请执行： export KUBECONFIG=$TARGET_FILE"
