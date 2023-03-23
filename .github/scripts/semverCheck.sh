#!/bin/bash
set -eEu
if [[ "$NEW_CALYPTIA_CORE_VERSION" =~ ^v?([0-9]+\.[0-9]+\.[0-9]+)$ ]] ; then
    NEW_CALYPTIA_CORE_VERSION=${BASH_REMATCH[1]}
    echo "Valid version string: $NEW_CALYPTIA_CORE_VERSION"
else
    echo "ERROR: Invalid semver string: $NEW_CALYPTIA_CORE_VERSION"
    exit 1
fi