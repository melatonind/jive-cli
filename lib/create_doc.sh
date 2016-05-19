#!/usr/bin/env bash

#Stop on error
set -o errexit
set -o xtrace

#Some TODO
# instead of README, accept any md file
# Define a name convention for subject i.e. document name
# Use given username
# Prettiffy this script

pandoc README.md > f1.tmp
sed -e 's/"/\\"/g' f1.tmp  > f2.tmp
cat f2.tmp | tr -d '\012' > f3.tmp
content=`cat f3.tmp`

curl -v -u user \
     -k --header "Content-Type: application/json" \
     -d '{ "type": "document",
           "subject": "Test document3",
           "visibility": "hidden",
           "tags": [one, two, three],
           "content":
              { "type": "text/html",
                "text": "<body>'"${content}"'</body>"
              }
         }' \
     "https://community.rea-group.com/api/core/v3/contents"

rm *.tmp
