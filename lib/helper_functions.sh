

function load_config {
  # Config file can set JIVE_ENDPOINT and JIVE_USER
  if [ -f ~/.jive ] ; then
    . ~/.jive
  fi

  if [ -z "$JIVE_ENDPOINT" ] ; then
    echo "No JIVE_ENDPOINT has been defined in ~/.jive"
    echo "Try running jive_config"
    exit 1
  fi
}

function interactive_config {
  if [ -f ~/.jive ] ; then
    . ~/.jive
  fi

  if [ -z "$JIVE_ENDPOINT" ] ; then
    echo "No endpoint is defined. guessing..."
    JIVE_ENDPOINT="https://community.$(hostname -d)/api/core/v3/"
  fi
  read -p "JIVE API Endpoint [$JIVE_ENDPOINT]: " NEW_JIVE_ENDPOINT
  if [ "$NEW_JIVE_ENDPOINT" ] ; then
    JIVE_ENDPOINT="$NEW_JIVE_ENDPOINT"
  fi
  # auto-detect endpoint
  # edit current value

  # edit username

  cat > ~/.jive << EOF
# jive-cli configuration
# generated by jive_config
JIVE_ENDPOINT="$JIVE_ENDPOINT"
EOF
}

# If nothing supplied, prompt for value
# If supplied "DOC-nnnnnn" then take nnnnnn
# If supplied "nnnnnn" then take nnnnnn
# otherwise, error
function set_doc_id {
  DOC_ID="$1"
  if [ -z "$DOC_ID" ]; then
    echo -n "Please supply a Document ID: "
    read DOC_ID
  fi
  if [ "${DOC_ID:0:4}" = "DOC-" ] ; then
	  DOC_ID="${DOC_ID:4}"
  fi
  if [[ "$DOC_ID" =~ ^[0-9]+$ ]] ; then 
	  echo "Using DOC-$DOC_ID"
  else
	  echo "Invalid DOC ID"
	  exit 1
  fi
}

function set_doc_id_for_update {
  DEFAULT=README
  if [ -z "$JIVE_FILENAME" ] ; then
    echo -n "Pls enter your filename - must be in current dir, .md files only [$DEFAULT]:"
    read filename
    if [ -z "$filename" ] ; then
      filename=$DEFAULT
    fi
  else
    filename="$JIVE_FILENAME"
  fi
  if [ -f "${filename}.md" ] ; then
    echo "Preparing for ${filename}.md"
  else
    echo "File not found: ${filename}.md"
    return 1
  fi
  JIVE_FILENAME="${filename}"

  load_doc_mapping "${JIVE_FILENAME}" "${REPO_NAME}"
}

# If we have a tty then use that
# otherwise we have to assume the default
# If you don't like that, set JIVE_USER in ~/.jive
function set_login {
  if [ "$JIVE_USER" ] ; then
    USER_ID="$JIVE_USER"
  else
    local default_user=$USER
    if tty -s < /dev/tty ; then
      echo -n "Username [$default_user]: " > /dev/tty
      read username < /dev/tty
      if [ -z "$username" ]; then
        USER_ID="$default_user"
      else
        USER_ID="$username"
      fi
    else
      USER_ID="$default_user"
    fi
  fi
}

# If we have a tty, use that otherwise we are SOL
function set_password {
  if [ "$JIVE_PASSWORD" ] ; then
    USER_PW="$JIVE_PASSWORD"
  else
    echo "Getting password"
    if tty -s ; then
      read -s -p "Password: " USER_PW
      echo
    elif tty -s < /dev/tty ; then
      read -s -p "Password: " USER_PW > /dev/tty < /dev/tty
      echo > /dev/tty
    else
      echo "Need a TTY to get the password"
      exit 1
    fi
  fi
}

function get_content_id {
  if [ -z "${DOC_ID}" ] ; then
	  echo "Error. Invalid DOC ID"
	  exit 1
  fi
  echo -n "Retrieving content ID from DOC-${DOC_ID}..."
  # tail -n +2 
  CONTENT_ID=$(curl -sS -u "$USER_ID":"$USER_PW" "${JIVE_ENDPOINT}contents?filter=entityDescriptor(102,${DOC_ID})" | jq -r .list[].contentID)
  if [[ "$CONTENT_ID" =~ ^[0-9]+$ ]] ; then 
	  echo "$CONTENT_ID"
  else
	  echo "Error. Invalid CONTENT ID"
	  curl -sS -u "$USER_ID":"$USER_PW" "${JIVE_ENDPOINT}contents?filter=entityDescriptor(102,${DOC_ID})" | jq .message
	  exit 1
  fi
}

function jive_search_by_subject {
  JIVE_SUBJECT="$1"
  echo "Searching for '$JIVE_SUBJECT'"
  SEARCH=$(echo $JIVE_SUBJECT | tr " " ",")
  echo "Searching for '$SEARCH'"
  curl -sS -u "$USER_ID":"$USER_PW" "${JIVE_ENDPOINT}contents?filter=search($SEARCH)" | \
	 tail -n +2 | \
	 jq -r " .list | map(if .subject == \"$JIVE_SUBJECT\" then ( \"DOC-\" + .id + \" in \" + .parentPlace.name + \" (\" + .author.displayName + \")\" ) else empty end ) "
}

function load_document {
  echo -n "Retrieving DOC-${DOC_ID}..."
  FILE1=$(mktemp -t jiveXXXX)
  FILE2=$(mktemp -t jiveXXXX)
  # tail -n +2
  curl -sS -u "$USER_ID":"$USER_PW" "${JIVE_ENDPOINT}contents/$CONTENT_ID" > $FILE1
  echo "done"
  SUBJECT=$( cat $FILE1 | jq -r .subject )
  JIVE_SUBJECT="$SUBJECT"
  PLACE_ID=$(cat $FILE1 | jq -r .parentPlace.placeID )
  JIVE_TAGS_JSON=$(cat $FILE1 | jq .tags )
  cat $FILE1 | jq -r .content.text > $FILE2
  cat $FILE2 > $FILE1
  CONTENT=$FILE1
  CONTENT_ORIGINAL=$FILE2
}

function edit_document {
  if [ -z "$JIVE_EDITOR" ] ; then
	  JIVE_EDITOR=vim
	  if [ "$VISUAL" ] ; then
		  JIVE_EDITOR="$VISUAL"
	  elif [ "$EDITOR" ] ; then
		  JIVE_EDITOR="$EDITOR"
	  fi
  fi
  echo -n "Would you like to edit "${SUBJECT}" [Y/n]? "
  read answer
  if [ "${answer}" = "y" -o "${answer}" = "Y" -o -z "${answer}" ]; then
    $JIVE_EDITOR $CONTENT
    if cmp -s $CONTENT $CONTENT_ORIGINAL ; then
      echo "No changes"
      false
    else
      echo -n "Changes detected. Saving..."
      CONTENT=$( cat $CONTENT | jq --slurp --raw-input . )
      true
    fi
  else
    false
  fi
}

# repo contains the git repo name to store the DOC ID against
# filename contains the filename index to store the DOC ID against
# CONTENT contans json escaped page contents
# SUBJECT contains the non-escaped page name
# PLACE_ID contains the jive place_id (where to create the content)
function create_document {
  OUTPUT=$(mktemp -t jiveXXXX)
  curl -sS -u "$USER_ID":"$USER_PW" \
     -k --header "Content-Type: application/json" \
     -d '{ "type": "document",
           "subject": "'"${SUBJECT}"'",
           "visibility": "place",
           "parent": "'"${JIVE_ENDPOINT}"'places/'"${PLACE_ID}"'",
           "tags": [readme],
           "content":
              { "type": "text/html",
                "text": '"${CONTENT}"'
              }
         }' \
     "${JIVE_ENDPOINT}/contents" > $OUTPUT

  FILETYPE=$(file $OUTPUT)
  if [ "${FILETYPE%% *}" = "gzip" ] ; then
    zcat $OUTPUT | grep "<title>"
  else
    NEW_ID=$(cat $OUTPUT | jq -r '.id')
    if [ "$NEW_ID" = "null" -o "$NEW_ID" = "" ] ; then
      cat $OUTPUT | jq -r '.error.status, .error.message '
    else
      echo "Created DOC-${NEW_ID}"
      save_doc_mapping "$filename" "$REPO_NAME" "$NEW_ID"
    fi
  fi


}

# CONTENT contans json escaped page contents
# SUBJECT contains the non-escaped page name
# CONTENT_ID contains the JIVE CONTENT_ID
# PLACE_ID containts the place ID loaded from the existing content
function update_document {
  OUTPUT=$(mktemp -t jiveXXXX)

  if [ -z "$JIVE_TAGS_JSON" ] ; then
	  JIVE_TAGS_JSON='[ ]'
  fi

  JSON='{ "subject": "'"${SUBJECT}"'",
           "type": "document",
           "status" : "published",
           "visibility": "place",
           "parent": "'"${JIVE_ENDPOINT}"'places/'"${PLACE_ID}"'",
           "tags" : '"${JIVE_TAGS_JSON}"',
           "content":
              { "type": "text/html",
                "text": '"${CONTENT}"'
              }
         }' 

  # Validate the JSON
  echo "$JSON" | jq . > /dev/null || return 1

  curl -sS -u "$USER_ID":"$USER_PW" -X PUT \
     -k --header "Content-Type: application/json" \
     -d "$JSON" \
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

# $1 = search string
# $2 = "exact" - find an exact match and set PLACE_ID
#    = "print" - print out a list for the user
function jive_search_by_place {
  if [ -z "$1" ]; then
    echo -n "Enter keyword for a place: "
    read search_string
  else
    search_string=$1
  fi
  search_string=$(echo "$search_string" | tr " " ",")
  index=0
  answer="n"
  tmp=$(mktemp -t jiveXXXX)
  while [ "$answer" = "n" ]; do
    curl -sS -u "$USER_ID":"$USER_PW" "${JIVE_ENDPOINT}places?filter=search(${search_string})&count=25&startIndex=${index}" > $tmp
    if [ "$(cat $tmp | jq .list[])" = "" ]; then
      #echo "There are no more places"
      return
    fi
    if [ "$2" = "exact" ] ; then
      ID=$(cat $tmp | jq -r ".list[] | select(.name == \"$1\") | .placeID")
      if [ "$ID" ] ; then
        PLACE_ID=$ID
	return
      fi
    else
      cat $tmp | jq -r '.list[] | .placeID + "   " + .name'
    fi
    #echo -n "Have you found the place you were looking for? [y/n]? "
    #read answer
    answer=n # keep searching
    index=$(($index+25))
  done
  if [ "$2" = "exact" ] ; then
    echo "No match found for place '$1'"
    echo "Select from:"
    jive_search_by_place "$1"
    exit 1
  fi
}

function set_place_id {
  if [ "$JIVE_PLACE" ] ; then
    JIVE_PLACE="$(echo "$JIVE_PLACE" | sed 's|%20| |g')"
    jive_search_by_place "$JIVE_PLACE" exact
    if [ -z "$PLACE_ID" ] ; then
      echo "No place ID found for '$JIVE_PLACE'"
      exit 1
    fi

    if [ "$JIVE_DEBUG" ] ; then
      echo "Found Place ID $PLACE_ID for place '$JIVE_PLACE'"
    fi
  else
  echo -n "Enter destination place ID: "
  read PLACE_ID
  echo $PLACE_ID
  fi
}

function convert_md {
  DEFAULT=README
  if [ -z "$JIVE_FILENAME" ] ; then
    echo -n "Pls enter your filename - must be in current dir, .md files only [$DEFAULT]:"
    read filename
    if [ -z "$filename" ] ; then
      filename=$DEFAULT
    fi
  else
    filename="$JIVE_FILENAME"
  fi
  if [ -f "${filename}.md" ] ; then
    echo "Converting ${filename}.md"
  else
    echo "File not found: ${filename}.md"
    return 1
  fi
  #CONTENT=$(pandoc -f markdown_github -t html5 --no-highlight --email-obfuscation=none "${filename}.md" | jq --slurp --raw-input . )
  MUNGE=$JIVE_DIR/lib/munge.pl
  CONTENT=$(echo '> _Uploaded by [JiveCLI](https://github.com/melatonind/jive-cli/)_' | cat "${filename}.md" - | pandoc -f markdown_github -t native | $MUNGE | pandoc -f native -t html5 --email-obfuscation=none | jq --slurp --raw-input . )
}

function load_repo {
  REPO_NAME=`git config --local remote.origin.url|sed -n 's#.*/\([^.]*\)\.git#\1#p'`
}

function jive_create_doc {

  set_login
  set_password
  #search_place
  set_place_id

  convert_md

  REPO_NAME=`git config --local remote.origin.url|sed -n 's#.*/\([^.]*\)\.git#\1#p'`

  

  OUTPUT=$(mktemp -t jiveXXXX)
  curl -sS -u "$USER_ID":"$USER_PW" \
     -k --header "Content-Type: application/json" \
     -d '{ "type": "document",
           "subject": "'"${REPO_NAME}"' '"${filename}"'",
           "visibility": "place",
           "parent": "'"${JIVE_ENDPOINT}"'places/'"${PLACE_ID}"'",
           "tags": [readme],
           "content":
              { "type": "text/html",
                "text": '"${CONTENT}"'
              }
         }' \
     "${JIVE_ENDPOINT}/contents" > $OUTPUT

  FILETYPE=$(file $OUTPUT)
  if [ "${FILETYPE%% *}" = "gzip" ] ; then
    zcat $OUTPUT | grep "<title>"
  else
    NEW_ID=$(cat $OUTPUT | jq -r '.id')
    if [ "$NEW_ID" = "null" -o "$NEW_ID" = "" ] ; then
      cat $OUTPUT | jq -r '.error.status, .error.message '
    else
      echo "Created DOC-${NEW_ID}"
      save_doc_mapping "$filename" "$REPO_NAME" "$NEW_ID"
    fi
  fi

}

# For documents created by jive-cli we keep a list of
# file -> DOC_ID mappings
# to allow for easy updates
# This is a text file which can added to scm along with the source document
function save_doc_mapping {
  filename="$1"
  repo="$2"
  id="$3"
  echo "${filename}|${repo}|${id}"

  #delete_doc_mapping "$filename" "$repo"
  echo "${filename}|${repo}|${id}" >> .jivecli
}

function load_doc_mapping {
  filename="$1"
  repo="$2"

  # We don't look at the repo yet
  DOC_ID=$(grep "^${filename}|" .jivecli | tail -1 | cut -d '|' -f 3)

  if [ -z "${DOC_ID}" ] ; then
    # try the old config format
    DOC_ID=$(grep "^${filename} " .jivecli | tail -1 | cut -d ' ' -f 2)
  fi
}

function delete_doc_mapping {
  filename="$1"
  repo="$2"

  OUTPUT=$(mktemp -t jiveXXXX)
  cat .jivecli | \
    awk "BEGIN { FS = \"|\" } ; { if ( \$1 == \"$filename\" && \$2 == \"$repo\") {} else { print \$0 } }" | \
    awk "BEGIN { FS = \" \" } ; { if ( \$1 == \"$basename\" ) {} else { print \$0 } }" | \
    > $OUTPUT
  mv $OUTPUT .jivecli
}

