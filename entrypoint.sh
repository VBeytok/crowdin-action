#!/bin/bash

set -ex

echo "STARTING CROWDIN ACTION..."

declare -a config_options=()
declare -a options=( "--no-progress" )

if [[ -n "$INPUT_BRANCH_NAME" ]]
then
    options+=( "--branch=$INPUT_BRANCH_NAME" )
fi

if [[ "$INPUT_DRYRUN_ACTION" = true ]]
then
    options+=( "--dryrun" )
fi

if [[ "$INPUT_UPLOAD_SOURCES" = true ]]
then
  echo "UPLOAD SOURCES"
  crowdin upload sources "${config_options[@]}" "${options[@]}"
fi

if [[ "$INPUT_UPLOAD_TRANSLATIONS" = true ]]
then
  echo "UPLOAD TRANSLATIONS"
  crowdin upload translations "${config_options[@]}" "${options[@]}"
fi
