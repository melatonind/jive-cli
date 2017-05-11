#!/bin/bash
# Invocation by source
# 1. Install shell aliases for the main commands
#
# Invocation by exec
# 2. Process the main command
#
# Invocation by exec of hard link
# 3. Process the main command
#

JIVE_COMMANDS="jive_config jive_create jive_edit jive_update_html jive_update_md jive_update_doc jive_search jive_search_places"

if [ "$JIVE_DEBUG" ] ; then
	env | grep ^JIVE_
	echo
fi

JIVE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ "${BASH_SOURCE[0]}" != "${0}" ] ; then
  for COMMAND in $JIVE_COMMANDS ; do
     if [ "${BASH_SOURCE[0]:0:1}" = "/" ] ; then
       alias $COMMAND="${BASH_SOURCE[0]} $COMMAND"
     else
       alias $COMMAND="${JIVE_DIR}/${BASH_SOURCE[0]} $COMMAND"
     fi
  done
  unset COMMAND
  unset JIVE_DIR
  unset JIVE_COMMANDS
else
  source $JIVE_DIR/lib/helper_functions.sh
  source $JIVE_DIR/lib/main_functions.sh

  for COMMAND in $JIVE_COMMANDS ; do
    if [ "$1" = "$COMMAND" ] ; then
      shift
      echo "calling $COMMAND $*"
      eval $COMMAND "$@"
      exit 0
    fi
  done
  echo "Unknown command"
  exit 1
fi

