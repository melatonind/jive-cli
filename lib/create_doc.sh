#!/usr/bin/env bash

#Stop on error

function convert_md {
  echo -n "Pls enter your filename - must be in current dir, .md files only [README]:"
  read filename
  if [ -z "$filename" ] ; then
    filename=README
  fi
  if [ -f "${filename}.md" ] ; then
    echo "Processing ${filename}.md"
  else
    echo "File not found: ${filename}.md"
    return 1
  fi
  CONTENT=$(pandoc -f markdown_github -t html "${filename}.md" | jq --slurp --raw-input . )
}

function create_doc {

  set_login
  set_password
(
set -o errexit
set -o xtrace
#Some TODO
# instead of README, accept any md file
# allow user to give a space in Jive for the document to be created
# delete visibility hidden line
# Prettiffy this script

echo -n "Pls enter your filename - must be in current dir, .md files only:"
read filename
pandoc ${filename}.md > f1.tmp
sed -e 's/"/\\"/g' f1.tmp  > f2.tmp
cat f2.tmp | tr -d '\012' > f3.tmp
CONTENT=`cat f3.tmp`

#assumes .MD file is in a git repo
REPO_NAME=`git config --local remote.origin.url|sed -n 's#.*/\([^.]*\)\.git#\1#p'`

curl -v -u "$USER_ID":"$USER_PW" \
     -k --header "Content-Type: application/json" \
     -d '{ "type": "document",
           "subject": "'"${REPO_NAME}"' '"${filename}"'",
           "visibility": "hidden",
           "tags": [readme],
           "content":
              { "type": "text/html",
                "text": "<body>'"${CONTENT}"'</body>"
              }
         }' \
     "https://community.rea-group.com/api/core/v3/contents"

rm f*.tmp
)
}
