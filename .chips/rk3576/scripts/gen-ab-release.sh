#!/bin/sh
# Fail closed: never stamp one release with artifacts from another build.
set -eu
target=${1:?rootfs target required}
release=${2:?release id required}
case "$release" in v1|v2) ;; *) echo "unsupported board release: $release" >&2; exit 1;; esac
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# Board directories physically live in device/rockchip/.chips/<chip>.
sdk=$(CDPATH= cd -- "$script_dir/../../../../.." && pwd)
test -d "$target/etc"
test -f "$sdk/u-boot/u-boot.bin"
test -f "$sdk/kernel/include/config/kernel.release"
uboot=$(LC_ALL=C strings "$sdk/u-boot/u-boot.bin" | sed -n '/^U-Boot [0-9].* (/p' | sort -u)
case "$uboot" in *'
'*|'') echo "missing/ambiguous U-Boot identity" >&2; exit 1;; esac
case "$uboot" in *"-abtest-$release") ;; *) echo "U-Boot release mismatch" >&2; exit 1;; esac
kernel=$(cat "$sdk/kernel/include/config/kernel.release")
case "$kernel" in *"-abtest-$release") ;; *) echo "kernel release mismatch" >&2; exit 1;; esac
dtb="$sdk/kernel/arch/arm64/boot/dts/rockchip/rk3576-100ask-dshanpi-a1-ab-$release.dtb"
test -f "$dtb"
getter=$(command -v fdtget || true)
if [ -z "$getter" ]; then
    getter="$sdk/buildroot/output/rockchip_rk3576_ab_test/host/bin/fdtget"
fi
test -x "$getter"
dtb_release=$("$getter" -t s "$dtb" /chosen 100ask,ab-test-version)
test "$dtb_release" = "$release"
test "$(cat "$target/etc/ab-test-version")" = "$release"
stamp=$(mktemp "$target/etc/.rk-ota-release.XXXXXX")
trap 'rm -f "$stamp"' EXIT HUP INT TERM
printf 'release=%s\nkernel=%s\nuboot=%s\ndtb=%s\nlayout=rk3576-ab-v2\nspl_abi=abctx2\n' \
    "$release" "$kernel" "$uboot" "$dtb_release" > "$stamp"
chmod 644 "$stamp"
mv "$stamp" "$target/etc/rk-ota-release"
