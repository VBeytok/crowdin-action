#!/bin/bash

set -e;

echo "STARTING CROWDIN ACTION...";

declare -a config_options=();
declare -a options=( "--no-progress" );

if [[ -n "$INPUT_BRANCH_NAME" ]]; then
    options+=( "--branch=$INPUT_BRANCH_NAME" );
fi

if [[ "$INPUT_DRYRUN_ACTION" = true ]]; then
    options+=( "--dryrun" );
fi

upload_sources() {
  echo "UPLOAD SOURCES";
  crowdin upload sources "${config_options[@]}" "${options[@]}";
}

upload_translations() {
  echo "UPLOAD TRANSLATIONS";
  crowdin upload translations "${config_options[@]}" "${options[@]}";
}

download_translations() {
  echo "DOWNLOAD TRANSLATIONS";
  crowdin download "${config_options[@]}" "${options[@]}";
}

create_pull_request() {
  TITLE="${1}";

  TRANSLATIONS_BRANCH="${2}";
  BASE_BRANCH=$(jq -r ".repository.default_branch" "$GITHUB_EVENT_PATH");

  AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}";
  HEADER="Accept: application/vnd.github.v3+json";
  HEADER="${HEADER}; application/vnd.github.antiope-preview+json; application/vnd.github.shadow-cat-preview+json";

  PULLS_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls";

  DATA="{\"base\":\"${BASE_BRANCH}\", \"head\":\"${TRANSLATIONS_BRANCH}\"}";
  RESPONSE=$(curl -sSL -H "${AUTH_HEADER}" -H "${HEADER}" -X GET --data "${DATA}" ${PULLS_URL});
  PR=$(echo "${RESPONSE}" | jq --raw-output '.[] | .head.ref');

  echo "response ref: ${PR}";

  if [[ "${PR}" != "${TRANSLATIONS_BRANCH}" ]]; then
      DATA="{\"title\":\"${TITLE}\", \"body\":\"${BODY}\", \"base\":\"${BASE_BRANCH}\", \"head\":\"${TRANSLATIONS_BRANCH}\"}";
      curl -sSL -H "${AUTH_HEADER}" -H "${HEADER}" -X POST --data "${DATA}" ${PULLS_URL};

  fi
}

push_to_branch() {
  TRANSLATIONS_BRANCH="downloaded-crowdin-translations";

  COMMIT_MESSAGE="New Crowdin translations by Github Action";

  REPO_URL="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git";

  echo "CONFIGURATION GIT USER";
  git config --global user.email "support+bot@crowdin.com";
  git config --global user.name "Crowdin Bot";

  git checkout -b ${TRANSLATIONS_BRANCH};

  if [[ -n $(git ls-remote --heads "${REPO_URL}" ${TRANSLATIONS_BRANCH}) ]]; then
     git pull "${REPO_URL}" ${TRANSLATIONS_BRANCH} --allow-unrelated-histories;
  fi

  download_translations;

  if [[ -n $(git status -s) ]]; then
      echo "PUSH TO BRANCH ${TRANSLATIONS_BRANCH}";
      git add .;
      git commit -m "${COMMIT_MESSAGE}";
      git push "${REPO_URL}";

      create_pull_request "${COMMIT_MESSAGE}" "${TRANSLATIONS_BRANCH}";
  else
      echo "NOTHING TO COMMIT";
  fi
}

if [[ "$INPUT_UPLOAD_SOURCES" = true ]]; then
  upload_sources;
fi

if [[ "$INPUT_UPLOAD_TRANSLATIONS" = true ]]; then
  upload_translations;
fi


if [[ "$INPUT_DOWNLOAD_TRANSLATIONS" = true ]]; then
  [[ -z "${GITHUB_TOKEN}" ]] && {
    echo "can not find GITHUB_TOKEN in environment variables";
    exit 1;
  };

  push_to_branch;
fi
