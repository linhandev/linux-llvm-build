#!/bin/bash
# CPF LLVM Linux-only Build Script
# 只构建 Linux x86_64 平台的 LLVM，在 Docker 中一站式完成

set -e

#############################################
# 配置项
#############################################

# Docker 镜像
DOCKER_IMAGE="swr.cn-north-4.myhuaweicloud.com/ci-service/openharmony-release-build-env-jnlp:1.0.3"

# LLVM 分支
LLVM_BRANCH="next/19.1.4-0.2"
LLVM_REMOTE="cpf"
LLVM_REMOTE_URL="git@gitcode.com:CPF-KMP-CMP/mpcore-llvm-kmp.git"

# 版本号
RELEASE_VERSION="10"

# Repo 配置
MANIFEST_URL="https://gitcode.com/CPF-KMP-CMP/manifest"
MANIFEST_BRANCH="main"
MANIFEST_XML="mpcore-llvm-kmp_next-19.1.4-0.2.xml"

#############################################
# Part 1: 代码同步（容器外）
#############################################

echo "============================================"
echo "Part 1: 代码同步"
echo "============================================"

# 获取 repo 工具
curl -sfL "https://gitee.com/oschina/repo/raw/fork_flow/repo-py3" -o ./repo

# 同步代码
echo "Initializing repo..."
init_args=(
  -u "${MANIFEST_URL}"
  -b "${MANIFEST_BRANCH}"
  -m "${MANIFEST_XML}"
  --depth=1
)
python3 ./repo init "${init_args[@]}"

echo "Syncing code..."
REPO_JOBS="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"
python3 ./repo sync -c -j"${REPO_JOBS}"

echo "Pulling LFS files..."
python3 ./repo forall -c 'git lfs pull'

# # 切换 LLVM 分支 （可选）
# echo "Switching LLVM branch to ${LLVM_BRANCH}..."
# cd toolchain/llvm-project

# git remote add "${LLVM_REMOTE}" "${LLVM_REMOTE_URL}" 2>/dev/null || true
# git fetch "${LLVM_REMOTE}"
# git switch "${LLVM_BRANCH}" 2>/dev/null || git checkout -b "${LLVM_BRANCH}"
# git reset --hard "${LLVM_REMOTE}/${LLVM_BRANCH}"

# # cd -

# 环境准备
echo "Running env_prepare.sh..."
bash toolchain/llvm-project/llvm-build/env_prepare.sh


#############################################
# Part 2: Docker 构建 + 打包
#############################################

echo "============================================"
echo "Part 2: Docker 构建 + 打包"
echo "============================================"

mkdir -p packages
cp package-llvm.sh packages/

docker run --rm \
    -v "$(pwd)":/llvm \
    -w /llvm \
    "${DOCKER_IMAGE}" \
    /bin/bash -c "
        set -e
        git config --global --add safe.directory /llvm/third_party/musl
        git config --global --add safe.directory /llvm/build
        git config --global user.email "ci@ci.ci"
        git config --global user.name "ci"
        cd /llvm/
        bash build-llvm.sh
        cd /llvm/packages
        bash package-llvm.sh
    "

echo "============================================"
echo "构建完成！"
echo "产物位置: packages/target_location/"
echo "============================================"

ls -lh packages/target_location/