#!/bin/bash
# Linux-only Platform Package Script
# 只打包 Linux x86_64 产物，overlay libcxx-ndk

set -e

clang_resource_version="19"
release_version="6"

WORK_DIR="$(pwd)"
OUTPUT_DIR="${WORK_DIR}/target_location"

CLANG_DEV="clang-dev-linux-x86_64.tar.gz"
LIBCXX_NDK="libcxx-ndk-dev-linux-x86_64.tar.gz"

FINAL_NAME="llvm-${clang_resource_version}14-x86_64-linux-dev-${release_version}"

echo "=== 解压 clang-dev ==="
mkdir -p clang-dev-linux
tar -xf "${CLANG_DEV}" -C clang-dev-linux

echo "=== 解压 libcxx-ndk ==="
mkdir -p libcxx-ndk
tar -xf "${LIBCXX_NDK}" -C libcxx-ndk

echo "=== Overlay libcxx-ndk 到 clang 目录 ==="
CLANG_DIR=$(find clang-dev-linux -type d -name "clang*" | head -1)

if [ -z "${CLANG_DIR}" ]; then
    echo "ERROR: Cannot find clang directory in clang-dev-linux"
    exit 1
fi

cp -r libcxx-ndk/lib/* "${CLANG_DIR}/lib/" 2>/dev/null || true
cp -r libcxx-ndk/include/* "${CLANG_DIR}/include/" 2>/dev/null || true

echo "=== 打包最终产物 ==="
mkdir -p "${OUTPUT_DIR}"

cd clang-dev-linux
tar -I pigz -cf "${OUTPUT_DIR}/${FINAL_NAME}.tar.gz" *
cd "${WORK_DIR}"

echo "=== 生成 SHA256 ==="
sha256sum "${OUTPUT_DIR}/${FINAL_NAME}.tar.gz" > "${OUTPUT_DIR}/${FINAL_NAME}.tar.gz.sha256"

echo "=== 清理临时目录 ==="
rm -rf clang-dev-linux libcxx-ndk

echo "=== 完成 ==="
ls -lh "${OUTPUT_DIR}/"