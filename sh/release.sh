#! /bin/sh

if [ $# -ne 1 ]; then
    echo "Usage: $0 <tag_name>"
    exit 1
else
    TAG=v"$1"
fi

git checkout main
git push origin main
git checkout release
git merge origin/main
git tag "$TAG" --force
git push origin "$TAG" --force
