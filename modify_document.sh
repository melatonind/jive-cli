#!/bin/bash

JIVE_ENDPOINT="https://community.rea-group.com/api/core/v3/"
DOC_ID=$1

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
  echo "Waiting..."
  CONTENT_ID=curl -u "$USER_ID":"$USER_PW" "${JIVE_ENDPOINT}contents?filter=entityDescriptor(102,${DOC_ID})" | tail -n +2 | jq -r .list[].contentID
  echo $CONTENT_ID
}

function load_document {
  echo "Downloading..."
  curl -u "$USER_ID":"$USER_PW" "${JIVE_ENDPOINT}contents/${CONTENT_ID}" > tmp.txt
}

set_login
set_password
get_content_id
load_document
