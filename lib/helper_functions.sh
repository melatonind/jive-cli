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
  FILE1=$(mktemp -t jiveXXXX)
  FILE2=$(mktemp -t jiveXXXX)
  curl -u "$USER_ID":"$USER_PW" "${JIVE_ENDPOINT}contents/$CONTENT_ID" | tail -n +2 > $FILE1
  SUBJECT=$( cat $FILE1 | jq -r .subject )
  cat $FILE1 | jq -r .content.text > $FILE2
  cat $FILE2 > $FILE1
  CONTENT=$FILE1
  CONTENT_ORIGINAL=$FILE2
}

function edit_document {
  echo -n "Would you like to edit "${SUBJECT}" [y/n]? "
  read answer
  if [ "${answer}" = "y" ]; then
    vim $CONTENT
    if cmp -s $CONTENT $CONTENT_ORIGINAL ; then
      echo "No changes"
      false
    else
      echo "Changes detected"
      CONTENT=$( cat $CONTENT | sed ':a;N;$!ba;s/\n/<br>/g' | jq --slurp --raw-input . )
      echo "Content is:"
      echo "$CONTENT"
      echo
      true
    fi
  else
    false
  fi
}

function update_document {
  OUTPUT=$(mktemp -t jiveXXXX)
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

