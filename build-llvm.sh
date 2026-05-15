#!/bin/bash
# Linux-only build wrapper - 基于 build.sh，跳过 windows 部分

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$SCRIPT_DIR"
LLVM_DIR=${WORK_DIR}/toolchain/llvm-project

# 同样的 patch 配置
PATCH_MAP=(
    "${WORK_DIR}/toolchain/llvm-project/llvm-build/0001-adapt-build-for-llvm19.patch:${WORK_DIR}/build"
    "${WORK_DIR}/toolchain/llvm-project/llvm-build/0001-adapt-musl-for-llvm19.patch:${WORK_DIR}/third_party/musl"
)

apply_patch() {
    local patch_file="$1"
    local target_dir="$2"
    
    if [ ! -f "$patch_file" ]; then
        echo "error: $patch_file not exit!!!!" >&2
        return 1
    fi
    if [ ! -d "$target_dir" ]; then
        echo "error: $target_dir not exit!!!" >&2
        return 1
    fi

    if (cd "$target_dir" && git apply --check "$patch_file" &>/dev/null); then
        echo "$patch_file can be applied  $target_dir"
        echo "begin apply patch"
        if (cd "$target_dir" && git am "$patch_file"); then
            echo "$patch_file apply success"
            return 0
        else
            echo "error: $patch_file apply failed" >&2
            return 1
        fi
    else
        echo "skip: $patch_file may have already been applied or there may be conflicts"
        return 1
    fi
}

build_llvm() {
    export PATH=${WORK_DIR}/prebuilts/python3/linux-x86/3.11.4/bin:$PATH
    
    LTO_FLAG=""
    if [ "$(uname -s)" = "Linux" ]; then
        LTO_FLAG="--no-lto"
    fi
    
    # 基于 build.sh，加 --no-build windows 和跳过所有 OHOS 目标
    /usr/bin/python3 ${WORK_DIR}/toolchain/llvm-project/llvm-build/build.py \
        --no-build-riscv64 \
        --no-build-loongarch64 \
        --no-build-mipsel \
        --no-build lldb-server \
        --no-build windows \
        --compression-format gz \
        $LTO_FLAG
}

main() {
    for entry in "${PATCH_MAP[@]}"; do
        IFS=':' read -r patch_file target_dir <<< "$entry"
        echo "------------------------------"
        apply_patch "$patch_file" "$target_dir"
    done
    build_llvm
}

main