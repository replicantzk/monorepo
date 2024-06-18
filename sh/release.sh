#! /bin/sh

if [ $# -ne 1 ]; then
    echo "Usage: $0 <tag_name>"
    exit 1
else
    TAG=v"$1"
fi

git checkout main
git tag "$TAG" --force
git push upstream "$TAG" --force
