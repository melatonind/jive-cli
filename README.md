# jive-cli

Let *jive-cli* change the way you think about publishing in community!

To get started, 
`source jive_cli.sh`


Update an existing document in VIM:

`jive_update <DOC-ID>`

Upload your markdown file:
`jive_create_doc [filename.md]`

Or update and existing version with
`jive_update_doc [filename.md] [<DOC-ID>]`

Update an existing jive document by supplying an html file:
`jive_update_html <DOC-ID>`

Can't remember your DOC ID? Search for the ID of an existing DOC
`JIVE_SUBJECT="Subject to search" jive_search_by_subject`

# Requirements
* bash
* jq
* pandoc

# Authors
* Mei Brough-Smyth
* Kimie Nakahara
* John Newbigin

# License
Please see [LICENSE.txt]

