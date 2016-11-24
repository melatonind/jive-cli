PLACE_ID=95549

# Edit an existing JIVE DOC in a text editor
# Uses the raw content from JIVE
function jive_edit {
  load_config
  set_doc_id $1
  set_login
  set_password
  get_content_id
  load_document
  if edit_document ; then
    update_document
  fi
}

function jive_create {
  load_config
  set_login
  set_password

  if [ "$1" ] ; then
    JIVE_FILENAME="$1"
  fi
  load_repo
  SUBJECT="${REPO_NAME} ${filename}"
  if convert_md ; then
    create_document
  fi
}

# Replace the contents of an existing JIVE DOC
# with the raw content from $2 or stdin
function jive_update_html {
  load_config
  set_doc_id $1
  set_login
  set_password
  get_content_id
  load_document
  CONTENT=$( cat $2 | jq --slurp --raw-input . )
  update_document
}

function jive_find_places {
  set_login
  set_password
  search_place $1
  set_place_id
}

function jive_update_doc {
  load_config
  set_login
  set_password
  set_doc_id_for_update
  get_content_id
  load_document
  if [ "$1" ] ; then
    JIVE_FILENAME="$1"
  fi
  load_repo
  if convert_md ; then
    update_document
  fi
}

function jive_search {
echo "IN $COMMAND $*"
  load_config
  set_login
  set_password
  jive_search_by_subject "$1"
}

function jive_config {
  interactive_config
}

