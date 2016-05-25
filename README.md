# jive-cli

Let *jive-cli* change the way you think about publishing in community!

To get started, 
`source jive_functions.sh`


Update an existing document in VIM:

`jive_update <DOC-ID>`

Upload your markdown file:
`jive_create_doc`

Or update and existing version with
`jive_update_doc <DOC-ID>`

Want to bypass the filename prompt?
`JIVE_FILENAME=README jive_update_doc <DOC-ID>`

Update an existing jive document by supplying an html file:
`jive_update_html <DOC-ID>`

Can't remember your DOC ID? Search for the ID of an existing DOC
`JIVE_SUBJECT="Subject to search" jive_search_by_subject`

# Requirements
* bash
* jq
* pandoc


