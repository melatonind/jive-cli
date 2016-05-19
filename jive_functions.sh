#!/bin/bash

source lib/helper_functions.sh
source lib/create_doc.sh

function update {
  set_doc_id $1
  set_login
  set_password
  get_content_id
  load_document
  if edit_document ; then
    update_document
  fi
}
