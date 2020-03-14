#!/usr/bin/env bash

# source helper functions
source ci/ci-functions.sh

# thank you https://stackoverflow.com/a/47441734
# this is requried to be able to checkout branches after fetching
test git config remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
test git fetch origin deployment

# TODO make test() work with | pipe
cat ci/deploy-whitelist | xargs git add -f
# commit generated files if necessary, it's ok if commit fails
git commit -m temporary-commit
# move to deployment branch
test git checkout deployment
test rm -rf *
# get the list of files that should be version controlled in deployment branch
test git checkout HEAD@{1} ci/deploy-whitelist
# add those files
cat ci/deploy-whitelist | xargs git checkout HEAD@{1}
test git --no-pager diff --staged
# unstage the whitelist
test git rm -f ci/deploy-whitelist

if [ "${TRAVIS}" == "true" ]; then
  test git config user.email "support@bluerobotics.com"
  test git config user.name "BlueRobotics-CI"
fi

git commit -m "update autogenerated files for $(git rev-parse HEAD@{2})" || return 0

# deploy
if [ ! -z ${TRAVIS_PULL_REQUEST} ] && [ ${TRAVIS_PULL_REQUEST} == "false" ]; then
    echob "Updating deployment branch.."
    test git remote set-url origin https://${GITHUB_TOKEN}@github.com/bluerobotics/ping-python
    test git push origin
else
    echob "PR detected, no deployment will be done."
fi