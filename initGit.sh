#!/usr/bin/env bash
# by zhangyc

set -e

function join { local IFS="$1"; shift; echo "$*"; }

if [ -z "$1" ]; then
    echo "Usage: $0 reviewer[,reviewer ...]"
    exit 1
fi

set -u

if [ -z `git remote | grep origin` ]; then
    echo "Remote origin not found, please clone this repository correctly or add origin remote by 'git remote add'."
    exit 1
fi

scp -p -P 29418 gerrit.zhenguanyu.com:hooks/commit-msg .git/hooks/

cat > .git/hooks/pre-commit << EOF
##!/bin/sh

if git-rev-parse --verify HEAD >/dev/null 2>&1 ; then
   against=HEAD
else
   # Initial commit: diff against an empty tree object
   against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi

# Find files with trailing whitespace
for FILE in \`exec git diff-index --check --cached \$against -- | sed '/^[+-]/d' | sed -E 's/:[0-9]+:.*//' | uniq\` ; do
    # Fix them!
    sed -i '' -E 's/[[:space:]]*$//' "\$FILE"
    git add "\$FILE"
done
EOF
chmod a+x .git/hooks/pre-commit

originURL=`git remote -v | grep fetch | perl -nle'print $& if m{(?<=origin\t)\S*}'`

(git remote remove review >& /dev/null || exit 0)

git remote add review $originURL

IFS=',' read -a reviewers <<< "$1"

sed -i '' '/\+refs\/heads\/\*:refs\/remotes\/review\/\*/d' .git/config
for i in "${!reviewers[@]}"; do
  reviewers[$i]="r=${reviewers[$i]}@fenbi.com"
done
echo "\tpush = HEAD:refs/for/master%`join , ${reviewers[@]}`" >> .git/config
