accounts.html: accounts.json
	./json_table_to_md.php $< | pandoc -t html -f markdown > $@
	jive_update_html 52305 accounts.html
