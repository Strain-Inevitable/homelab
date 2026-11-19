#!/bin/bash

shopt -s globstar nullglob

TARGET_DIR="/home/strain-inevitable/homelab"

for dir in "$TARGET_DIR"/**/; do
	dir="${dir%/}"

	# Skip root of tree
	[[ "$dir" == "$TARGET_DIR" ]] && continue

	subdirs=("$dir"/*/)
	if [ ${#subdirs[@]} -eq 0 ]; then
		FOLDER="${dir##*/}"

		# Skip leaves with no Terraform files
		tf_files=("$dir"/*.tf)
		[ ${#tf_files[@]} -eq 0 ] && continue

		echo "================================================"
		echo "= Directory: $FOLDER ($dir)"
		echo "================================================"

		terraform -chdir="$dir" init --upgrade
		echo ""
	fi
done
