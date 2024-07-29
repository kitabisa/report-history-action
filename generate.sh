#!/usr/bin/env bash

# Create directories for gh-pages and report-history if they don't exist
echo "Creating directories: ./${INPUT_GH_PAGES} and ./${INPUT_REPORT_HISTORY}"
mkdir -p ./${INPUT_GH_PAGES}
mkdir -p ./${INPUT_REPORT_HISTORY}

# Copy all contents from gh-pages to report-history
echo "Copying contents from ./${INPUT_GH_PAGES} to ./${INPUT_REPORT_HISTORY}"
cp -r ./${INPUT_GH_PAGES}/. ./${INPUT_REPORT_HISTORY}

# Get repository name from full input (owner/repo)
REPOSITORY_OWNER_SLASH_NAME=${INPUT_GITHUB_REPO}
REPOSITORY_NAME=${REPOSITORY_OWNER_SLASH_NAME##*/}
GITHUB_PAGES_WEBSITE_URL="https://${INPUT_GITHUB_REPO_OWNER}.github.io/${REPOSITORY_NAME}"

# If a subfolder is specified, adjust paths and URL
if [[ ${INPUT_SUBFOLDER} != '' ]]; then
  INPUT_REPORT_HISTORY="${INPUT_REPORT_HISTORY}/${INPUT_SUBFOLDER}"
  INPUT_GH_PAGES="${INPUT_GH_PAGES}/${INPUT_SUBFOLDER}"
  mkdir -p ./${INPUT_REPORT_HISTORY}
  GITHUB_PAGES_WEBSITE_URL="${GITHUB_PAGES_WEBSITE_URL}/${INPUT_SUBFOLDER}"
  echo "Adjusted paths for subfolder: INPUT_REPORT_HISTORY=${INPUT_REPORT_HISTORY}, INPUT_GH_PAGES=${INPUT_GH_PAGES}"
  echo "Updated GITHUB_PAGES_WEBSITE_URL: ${GITHUB_PAGES_WEBSITE_URL}"
fi

# Removing the folder with the smallest number
COUNT=$( (ls ./${INPUT_REPORT_HISTORY} | wc -l))
echo "Count folders in report-history: ${COUNT}"

# Determine which folders to keep based on INPUT_KEEP_REPORTS
echo "Keep reports count ${INPUT_KEEP_REPORTS}"
echo "Removing the folder with the smallest number..."

if [[ "${INPUT_REPORT_FOLDER}" == *"allure-results"* ]]; then
  INPUT_KEEP_REPORTS=$((INPUT_KEEP_REPORTS+1))
  echo "If ${COUNT} > ${INPUT_KEEP_REPORTS}"
  if ((COUNT > INPUT_KEEP_REPORTS)); then
    cd ./${INPUT_REPORT_HISTORY}
    echo "Remove index.html last-history"
    rm index.html last-history -rv
    echo "Remove old reports"
    ls | sort -n | head -n -$((${INPUT_KEEP_REPORTS}-2)) | xargs rm -rv;
    cd ${GITHUB_WORKSPACE}
  fi

  #echo "index.html"
  echo "<!DOCTYPE html><meta charset=\"utf-8\"><meta http-equiv=\"refresh\" content=\"0; URL=${GITHUB_PAGES_WEBSITE_URL}/${INPUT_GITHUB_RUN_NUM}/index.html\">" >./${INPUT_REPORT_HISTORY}/index.html # path
  echo "<meta http-equiv=\"Pragma\" content=\"no-cache\"><meta http-equiv=\"Expires\" content=\"0\">" >> ./${INPUT_REPORT_HISTORY}/index.html
  #cat ./${INPUT_REPORT_HISTORY}/index.html

  #echo "executor.json"
  echo '{"name":"GitHub Actions","type":"github","reportName":"Allure Report with history",' > executor.json
  echo "\"url\":\"${GITHUB_PAGES_WEBSITE_URL}\"," >> executor.json # ???
  echo "\"reportUrl\":\"${GITHUB_PAGES_WEBSITE_URL}/${INPUT_GITHUB_RUN_NUM}/\"," >> executor.json
  echo "\"buildUrl\":\"${INPUT_GITHUB_SERVER_URL}/${INPUT_GITHUB_REPO}/actions/runs/${INPUT_GITHUB_RUN_ID}\"," >> executor.json
  echo "\"buildName\":\"GitHub Actions Run #${INPUT_GITHUB_RUN_ID}\",\"buildOrder\":\"${INPUT_GITHUB_RUN_NUM}\"}" >> executor.json
  #cat executor.json
  mv ./executor.json ./${INPUT_REPORT_FOLDER}

  #environment.properties
  # echo "URL=${GITHUB_PAGES_WEBSITE_URL}" >> ./${INPUT_REPORT_FOLDER}/environment.properties

  echo "keep allure history from ${INPUT_GH_PAGES}/last-history to ${INPUT_REPORT_FOLDER}/history"
  cp -r ./${INPUT_GH_PAGES}/last-history/. ./${INPUT_REPORT_FOLDER}/history

  echo "generating report from ${INPUT_REPORT_FOLDER} to ${INPUT_ALLURE_REPORT} ..."
  #ls -l ${INPUT_REPORT_FOLDER}
  allure generate --clean ${INPUT_REPORT_FOLDER} -o ${INPUT_ALLURE_REPORT}
  #echo "listing report directory ..."
  #ls -l ${INPUT_ALLURE_REPORT}

  echo "copy allure-report to ${INPUT_REPORT_HISTORY}/${INPUT_GITHUB_RUN_NUM}"
  cp -r ./${INPUT_ALLURE_REPORT}/. ./${INPUT_REPORT_HISTORY}/${INPUT_GITHUB_RUN_NUM}
  echo "copy allure-report history to /${INPUT_REPORT_HISTORY}/last-history"
  cp -r ./${INPUT_ALLURE_REPORT}/history/. ./${INPUT_REPORT_HISTORY}/last-history
else
  if ((COUNT == INPUT_KEEP_REPORTS)); then
    echo "If ${COUNT} == ${INPUT_KEEP_REPORTS}"
    ls -d ${INPUT_REPORT_HISTORY}/*/ | sort -V | head -n 1 | xargs rm -rv
  elif ((COUNT > INPUT_KEEP_REPORTS)); then
    echo "elif ${COUNT} > ${INPUT_KEEP_REPORTS}"
    ls -d ${INPUT_REPORT_HISTORY}/*/ | sort -V | head -n -$((${INPUT_KEEP_REPORTS} - 1)) | xargs rm -rv
  fi

  # Copy INPUT_REPORT_FOLDER folder to INPUT_SUBFOLDER
  if [ -d "${INPUT_REPORT_FOLDER}" ]; then
    echo "Copying ${INPUT_REPORT_FOLDER} to ${INPUT_SUBFOLDER}"
    cp -r "${INPUT_REPORT_FOLDER}" "${INPUT_SUBFOLDER}"
  fi

  # Copy contents of INPUT_SUBFOLDER to INPUT_REPORT_HISTORY/INPUT_GITHUB_RUN_NUM
  if [ -d "${INPUT_SUBFOLDER}" ]; then
    echo "Copying contents of ${INPUT_SUBFOLDER} to ${INPUT_REPORT_HISTORY}/${INPUT_GITHUB_RUN_NUM}"
    cp -r ./${INPUT_SUBFOLDER}/. ./${INPUT_REPORT_HISTORY}/${INPUT_GITHUB_RUN_NUM}
  else
    echo "Folder ${INPUT_SUBFOLDER} not found."
  fi
fi
