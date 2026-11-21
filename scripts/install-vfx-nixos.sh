#!/usr/bin/env bash
set -euo pipefail

wheel=nvidia_vfx-0.2.0.0-cp312-abi3-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl
checksum=0252866a7b798a6f92c8543443d88f716e8c5bbc6a7ddd77a2754728dada9fa8
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT

curl -fL "https://pypi.nvidia.com/nvidia-vfx/$wheel" -o "$tmp/$wheel"
printf '%s  %s\n' "$checksum" "$tmp/$wheel" | sha256sum --check
unzip -q "$tmp/$wheel" 'nvvfx/libs/*.so*' 'nvidia_vfx.libs/*.so*' -d "$tmp"

# The loader expects unversioned names and a sibling directory for CUDA.
libs="$tmp/nvvfx/libs"
for library in "$libs"/*.so.*; do
	link="${library%%.so.*}.so"
	if [[ ! -e "$link" ]]; then
		ln -s "${library##*/}" "$link"
	fi
done

mkdir -p "$HOME/.local/lib/vsr-player" "$HOME/.local/nvidia_vfx.libs"
cp -a --remove-destination "$libs/." "$HOME/.local/lib/vsr-player/"
cp -a --remove-destination "$tmp/nvidia_vfx.libs/." "$HOME/.local/nvidia_vfx.libs/"
