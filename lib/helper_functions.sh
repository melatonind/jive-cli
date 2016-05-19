#!/bin/bash

JIVE_ENDPOINT="https://community.rea-group.com/api/core/v3/"

function set_doc_id {
  if [ -z "$1" ]; then
    echo -n "Please supply a Document ID: "
    read DOC_ID
  else
    DOC_ID=$1
    echo "Set doc_id"
  fi
}

function set_login {
  local default_user=$USER
  echo -n "Username [$default_user]: "
  read username
  if [ -z "$username" ]; then
    USER_ID="$default_user"
  else
    USER_ID="$username"
  fi
}

function set_password {
  read -s -p "Password: " USER_PW
  echo
}

function get_content_id {
  echo "Retrieving content ID from DOC-${DOC_ID}..."
  CONTENT_ID=$(curl -u "$USER_ID":"$USER_PW" "${JIVE_ENDPOINT}contents?filter=entityDescriptor(102,${DOC_ID})" | tail -n +2 | jq -r .list[].contentID)
}

function load_document {
  echo "Retrieving DOC-${DOC_ID}..."
  curl -u "$USER_ID":"$USER_PW" "${JIVE_ENDPOINT}contents/$CONTENT_ID" | tail -n +2 > tmp.txt
  SUBJECT=$( cat tmp.txt | jq .subject )
  CONTENT=$( cat tmp.txt | jq .content.text )
  echo $CONTENT > tmp.txt
}

function edit_document {
  echo -n "Would you like to edit "${SUBJECT}" [y/n]? "
  read answer
  if [ "${answer}" = "y" ]; then
    vim tmp.txt < `tty` > `tty`
    CONTENT=$( cat tmp.txt )
  else
    echo ":( control D out pls"
  fi
}

function update_document {
  curl -s -u "$USER_ID":"$USER_PW" -X PUT \
     -k --header "Content-Type: application/json" \
     -d '{ "subject": '"${SUBJECT}"',
           "type": "document",
           "status" : "published",
           "tags" : [ ],
           "content":
              { "type": "text/html",
                "text": '"${CONTENT}"'
              }
         }' \
     "${JIVE_ENDPOINT}contents/${CONTENT_ID}" > output.txt
  echo "Uploaded DOC-${DOC_ID}"
}
