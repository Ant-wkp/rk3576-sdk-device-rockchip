#!/bin/sh
# Test marker only: do not let rsync's equal-size/equal-second quick check
# mistake V1 and V2 markers created in the same second for identical contents.
set -eu
test_overlay_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
test_target_dir=${1:?target directory is required}
test -d "$test_target_dir/etc"
rsync -a --checksum --chmod=u=rwX,go=rX "$test_overlay_dir/etc/" "$test_target_dir/etc/"
rm -f "$test_target_dir/etc/init.d/S99ab-watchdog"
exec sh "$test_overlay_dir/../../scripts/gen-ab-release.sh" "$test_target_dir" v1
