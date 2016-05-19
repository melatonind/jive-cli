#!/bin/bash

JIVE_ENDPOINT="https://community.rea-group.com/api/core/v3/"

# Config file can set JIVE_ENDPOINT and JIVE_USER
if [ -f ~/.jive ] ; then
	. ~/.jive
fi


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
  if [ "$JIVE_USER" ] ; then
    USER_ID="$JIVE_USER"
  else
    local default_user=$USER
    echo -n "Username [$default_user]: "
    read username
    if [ -z "$username" ]; then
      USER_ID="$default_user"
    else
      USER_ID="$username"
    fi
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
    vim tmp.txt
    CONTENT=$( cat tmp.txt | jq --slurp --raw-input . )
    echo "Content is:"
    echo "$CONTENT"
    echo
  else
    echo ":( control D out pls"
  fi
}

function update_document {
  OUTPUT=$(mktemp --tmpdir jiveXXXX)
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
     "${JIVE_ENDPOINT}contents/${CONTENT_ID}" > $OUTPUT
  FILETYPE=$(file $OUTPUT)
  if [ "${FILETYPE%% *}" = "gzip" ] ; then
    zcat $OUTPUT | grep "<title>"
  else
    NEW_VERSION=$(cat $OUTPUT | jq -r '.version')
    if [ "$NEW_VERSION" = "null" -o "$NEW_VERSION" = "" ] ; then
      cat $OUTPUT | jq -r '.error.status, .error.message '
    else
      echo "Uploaded DOC-${DOC_ID} version ${NEW_VERSION}"
    fi
  fi
}

