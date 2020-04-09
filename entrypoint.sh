#!/bin/sh

set -ex

echo "STARTING CROWDIN ACTION..."

declare -a config_options=()
declare -a oprions=( "--no-progress" )

if [[ -n "$INPUT_BRANCH_NAME" ]] ; then
    oprions+=( "--branch=$INPUT_BRANCH_NAME" )
fi

if [[ "$INPUT_DRYRUN_ACTION" = true ]] ; then
    oprions+=( "--dryrun" )
fi

if [[ "$INPUT_UPLOAD_SOURCES" = true ]] ; then
  echo "UPLOAD SOURCES"
  crowdin upload sources "${config_options[@]}" "${oprions[@]}"
fi

if [[ "$INPUT_UPLOAD_TRANSLATIONS" = true ]] ; then
  echo "UPLOAD TRANSLATIONS"
  crowdin upload translations "${config_options[@]}" "${oprions[@]}"
fi
