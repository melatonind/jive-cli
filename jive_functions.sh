#!/bin/bash

source lib/helper_functions.sh
source lib/create_doc.sh

function update {
  set_doc_id $1
  set_login
  (
  set_password
  get_content_id
  load_document
  if edit_document ; then
    update_document
  fi
  )
}

function update_html {
  set_doc_id $1
  set_login
  (
  set_password
  get_content_id
  load_document
  CONTENT=$( cat $2 | jq --slurp --raw-input . )
  update_document
  )
}

function find_places {
  set_login
  (
  set_password
  search_place $1
  set_place_id
  )
}

function update_doc {
  set_doc_id $1
  set_login
  set_password
  get_content_id
  load_document
  if convert_md ; then
    update_document
  fi
}

