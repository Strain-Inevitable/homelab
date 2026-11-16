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

		(
			# Source local environment files
			if [ -f "$dir/.env" ]; then
				source "$dir/.env"
			fi

			# Check for changes (0 = no change, 1 = error, 2 = changes)
			terraform -chdir="$dir" plan -detailed-exitcode -out=tfplan
			plan_exit=$?

			if [ $plan_exit -eq 0 ]; then
				# Skip on no changes
				echo "No changes for $FOLDER. Skipping."
			elif [ $plan_exit -eq 1 ]; then
				# Halt on error
				echo "Error in $FOLDER. Halting."
				exit 1
			elif [ $plan_exit -eq 2 ]; then
				# Ask for confirmation to apply on changes
				read -rp "Apply plan for $FOLDER? [y/N]: " confirm

				if [[ "$confirm" =~ ^[Yy]$ ]]; then
					# Apply the plan
					terraform -chdir="$dir" apply tfplan
				else
					echo "Skipping $FOLDER"
				fi
			fi
		)
		subshell_exit=$?

		# Remove temporary plan file
		rm -f "$dir/tfplan"

		# Halt the entire program if the subshell exited with code 1
		if [ $subshell_exit -ne 0 ]; then
			exit 1
		fi

		echo ""
	fi
done
