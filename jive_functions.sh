#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/lib/helper_functions.sh
source $DIR/lib/create_doc.sh

function jive_update {
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

function jive_update_html {
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

function jive_find_places {
  set_login
  (
  set_password
  search_place $1
  set_place_id
  )
}

function jive_update_doc {
  set_doc_id_for_update
  set_login
  set_password
  get_content_id
  load_document
  if convert_md ; then
    update_document
  fi
}

