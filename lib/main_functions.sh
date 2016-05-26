PLACE_ID=95549

function jive_edit {
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
  set_login
  (
  set_password
  set_doc_id_for_update
  get_content_id
  load_document
  if convert_md ; then
    update_document
  fi
  )
}

function jive_config {
  interactive_config
}

