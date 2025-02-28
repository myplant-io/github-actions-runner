#!/usr/bin/env bash
set -e

readonly _GH_API_ENDPOINT="${GH_API_ENDPOINT:-https://github.com}"

if [ -z "$RUNNER_TOKEN" ]
then
  echo "Must define RUNNER_TOKEN variable"
  exit 255
fi

if [ -z "$GH_REPO" ]
then
  readonly RUNNER_URL=${_GH_API_ENDPOINT}/${GH_ORG}
else
  readonly RUNNER_URL="${_GH_API_ENDPOINT}/${GH_ORG}/${GH_REPO}"
fi

sudo install-runner

# Reconfigure from the clean state in case of runner failures/restarts
./config.sh remove --token "${RUNNER_TOKEN}"
./config.sh --unattended --url "${RUNNER_URL}" --token "${RUNNER_TOKEN}" --ephemeral

exec "./run.sh" "${RUNNER_ARGS}"
