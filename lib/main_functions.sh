
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
  set_place_id

  if [ "$1" ] ; then
    JIVE_FILENAME="$1"
  fi
  if [ "$JIVE_SUBJECT" ] ; then
      SUBJECT="$(echo "$JIVE_SUBJECT" | sed 's|%20| |g')"
  else
  	load_repo
  	SUBJECT="${REPO_NAME} ${filename}"
  fi
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

  if [ "$JIVE_SUBJECT" ] ; then
	SUBJECT="$JIVE_SUBJECT"
  else
  	load_repo
  	SUBJECT="${REPO_NAME} ${filename}"
  fi
 
  if convert_md ; then
    update_document
  fi
}

function jive_search {
  load_config
  set_login
  set_password
  jive_search_by_subject "$1"
}

function jive_search_places {
  load_config
  set_login
  set_password
  jive_search_by_place "$1"
}

function jive_config {
  interactive_config
}

