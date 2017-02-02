#!/usr/bin/perl -n
if($_ =~ "^,CodeBlock"){
	# ,CodeBlock ("",["bash"],[]) "cd atuin<br>authenticate<br>auto/deploy-role<br>auto/import-image"
	# ,CodeBlock ("",[],[]) "auto/remove-image [<version>|all]"
	if(/^,CodeBlock \(\"\",\[(\"[a-z]*\"){0,1}\],\[\]\) \"(.*)\"(]?)$/) {
		# $1 = language
		# $2 = code
		@lines = split(/([^\\])\\n/, $2);
		#foreach my $line (@lines) {
		for(my $n = 0; $n <= $#lines; $n+= 2) {
			$code = $lines[$n].$lines[$n + 1];
			print ",CodeBlock (\"\",[$1],[]) \"$code\"\n"
		}
		# If there is a trailing ] then it will be $3
		print $3
	} else {
		print "ZZZ".$_
	}
} else {
	print $_
}

