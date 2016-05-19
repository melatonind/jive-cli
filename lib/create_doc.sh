#!/usr/bin/env bash

#Stop on error

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

pandoc README.md > f1.tmp
sed -e 's/"/\\"/g' f1.tmp  > f2.tmp
cat f2.tmp | tr -d '\012' > f3.tmp
content=`cat f3.tmp`

#assumes .MD file is in a git repo
doc_name=`git config --local remote.origin.url|sed -n 's#.*/\([^.]*\)\.git#\1#p'`

curl -v -u "$USER_ID":"$USER_PW" \
     -k --header "Content-Type: application/json" \
     -d '{ "type": "document",
           "subject": "'"${doc_name}"' README",
           "visibility": "hidden",
           "tags": [readme],
           "content":
              { "type": "text/html",
                "text": "<body>'"${content}"'</body>"
              }
         }' \
     "https://community.rea-group.com/api/core/v3/contents"

rm *.tmp
)
}
