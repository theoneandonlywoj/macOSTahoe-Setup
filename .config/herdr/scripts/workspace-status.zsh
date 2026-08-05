#!/bin/zsh
set -euo pipefail

printf 'Hello, %s!\n\n' "${HERDR_STATUS_GIT_USER:-there}"
printf 'Location: %s\n' "${HERDR_STATUS_CWD:-unknown}"
printf 'Branch: %s\n' "${HERDR_STATUS_BRANCH:-none}"
printf 'Workspace: %s (%s)\n' "${HERDR_STATUS_WORKSPACE_LABEL:-unknown}" "${HERDR_STATUS_WORKSPACE_ID:-unknown}"
printf 'Source workspace: %s\n' "${HERDR_STATUS_SOURCE_WORKSPACE:-none}"
