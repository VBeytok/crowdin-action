#!/bin/bash

set -e

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


if [[ "$INPUT_DOWNLOAD_TRANSLATIONS" = true ]]
then
  [[ -z "${GITHUB_TOKEN}" ]] && {
    echo 'Missing GITHUB_TOKEN';
    exit 1;
  };

  echo "DOWNLOAD TRANSLATIONS"
  crowdin download "${config_options[@]}" "${options[@]}"

  echo "CONFIGURATION GIT USER"
  git config --global user.email "support+bot@crowdin.com"
  git config --global user.name "Crowdin Bot"

  TRANSLATIONS_BRANCH="downloaded-crowdin-translations"

  git checkout -b ${TRANSLATIONS_BRANCH}

  if [[ -n $(git status -s) ]]
  then
      echo "PUSH TO BRANCH ${TRANSLATIONS_BRANCH}"
      git add .
      git commit -m "New Crowdin translations by Github Action"
      git push "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
  else
      echo "NOTHING TO COMMIT"
  fi
fi
