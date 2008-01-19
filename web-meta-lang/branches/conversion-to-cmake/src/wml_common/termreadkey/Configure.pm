#!/usr/bin/perl

# Configure.pm. Version 1.00          Copyright (C) 1995, Kenneth Albanowski
#
#  You are welcome to use this code in your own perl modules, I just
#  request that you don't distribute modified copies without making it clear
#  that you have changed something. If you have a change you think is worth
#  merging into the original, please contact me at kjahds@kjahds.com or
#  CIS:70705,126


# Todo: clean up redudant code in CPP, Compile, Link, and Execute
#

package Configure;

use Carp;
require Exporter;
@ISA=(Exporter);
@EXPORT=qw( CPP Compile Link Execute
				FindHeader FindLib
				Apply ApplyHeaders ApplyLibs ApplyHeadersAndLibs 
				ApplyHeadersAndLibsAndExecute
				CheckHeader CheckStructure CheckField
				CheckHSymbol CheckSymbol CheckLSymbol
				GetSymbol GetTextSymbol GetNumericSymbol 
				GetConstants);

use Cwd;
use Config;
($C_usrinc, $C_libpth, $C_cppstdin, $C_cppflags, $C_cppminus,
$C_ccflags,$C_ldflags,$C_cc,$C_libs) =
	 @Config{qw( usrinc libpth cppstdin cppflags cppminus
					 ccflags ldflags cc libs)};

$Verbose=0;

=head1 NAME

Configure.pm - provide auto-configuration utilities

=head1 SUMMARY

This perl module provides tools to figure out what is present in the C
compilation environment. This is intended mostly for perl extensions to use
to configure themselves. There are a number of functions, with widely varying
levels of specificity, so here is a summary of what the functions can do:


CheckHeader:		Look for headers.

CheckStructure:	Look for a structure.

CheckField:		Look for a field in a structure.

CheckHSymbol:		Look for a symbol in a header.

CheckLSymbol:		Look for a symbol in a library.

CheckSymbol:		Look for a symbol in a header and library.

GetTextSymbol:		Get the contents of a symbol as text.

GetNumericSymbol:	Get the contents of a symbol as a number.	

Apply:		Try compiling code with a set of headers and libs.

ApplyHeaders:		Try compiling code with a set of headers.

ApplyLibraries:	Try linking code with a set of libraries.

ApplyHeadersAndLibaries:	You get the idea.

ApplyHeadersAndLibariesAnExecute:	You get the idea.

CPP:		Feed some code through the C preproccessor.

Compile:	Try to compile some C code.

Link:	Try to compile & link some C code.

Execute:	Try to compile, link, & execute some C code.

=head1 FUNCTIONS

=cut

# Here we go into the actual functions

=head2 CPP

Takes one or more arguments. The first is a string containing a C program.
Embedded newlines are legal, the text simply being stuffed into a temporary
file. The result is then fed to the C preproccessor (that preproccessor being
previously determined by perl's Configure script.) Any additional arguments
provided are passed to the preprocessing command.

In a scalar context, the return value is either undef, if something went wrong,
or the text returned by the preprocessor. In an array context, two values are 
returned: the numeric exit status and the output of the preproccessor.

=cut

sub CPP { # Feed code to preproccessor, returning error value and output

	my($code,@options) = @_;
	my($options) = join(" ",@options);
	my($file) = "tmp$$";
	my($in,$out) = ($file.".c",$file.".o");

	open(F,">$in");
	print F $code;
	close(F);

	print "Preprocessing |$code|\n" if $Verbose;
	my($result) = scalar(`$C_cppstdin $C_cppflags $C_cppminus $options < $in 2>/dev/null`);
	print "Executing '$C_cppstdin $C_cppflags $C_cppminus $options < $in 2>/dev/null'\n"  if $Verbose;


	my($error) = $?;
	print "Returned |$result|\n" if $Verbose;
	unlink($in,$out);
	return ($error ? undef : $result) unless wantarray;
	($error,$result);
}

=head2 Compile

Takes one or more arguments. The first is a string containing a C program.
Embedded newlines are legal, the text simply being stuffed into a temporary
file. The result is then fed to the C compiler (that compiler being
previously determined by perl's Configure script.) Any additional arguments
provided are passed to the compiler command.

In a scalar context, either 0 or 1 will be returned, with 1 indicating a
successful compilation. In an array context, three values are returned: the
numeric exit status of the compiler, a string consisting of the output
generated by the compiler, and a numeric value that is false if a ".o" file
wasn't produced by the compiler, error status or no.

=cut

sub Compile { # Feed code to compiler. On error, return status and text
	my($code,@options) = @_;
	my($options)=join(" ",@options);
	my($file) = "tmp$$";
	my($in,$out) = ($file.".c",$file.".o");

	open(F,">$in");
	print F $code;
	close(F);
	print "Compiling |$code|\n"  if $Verbose;
	my($result) = scalar(`$C_cc $C_ccflags -c $in $C_ldflags $C_libs $options 2>&1`);
	print "Executing '$C_cc $C_ccflags -c $in $C_ldflags $C_libs $options 2>&1'\n"  if $Verbose;
	my($error) = $?;
   my($error2) = ! -e $out;
	unlink($in,$out);
	return (($error || $error2) ? 0 : 1) unless wantarray;
	($error,$result,$error2);
}

=head2 Link

Takes one or more arguments. The first is a string containing a C program.
Embedded newlines are legal, the text simply being stuffed into a temporary
file. The result is then fed to the C compiler and linker (that compiler and
linker being previously determined by perl's Configure script.) Any
additional arguments provided are passed to the compilation/link command.

In a scalar context, either 0 or 1 is returned, with 1 indicating a
successful compilation. In an array context, two values are returned: the
numeric exit status of the compiler/linker, and a string consisting of the
output generated by the compiler/linker.

Note that this command I<only> compiles and links the C code. It does not
attempt to execute it.

=cut

sub Link { # Feed code to compiler and linker. On error, return status and text
	my($code,@options) = @_;
	my($options) = join(" ",@options);
	my($file) = "tmp$$";
	my($in,$out) = $file.".c",$file.".o";

	open(F,">$in");
	print F $code;
	close(F);
	print "Linking |$code|\n" if $Verbose;
	my($result) = scalar(`$C_cc $C_ccflags -o $file $in $C_ldflags $C_libs $options 2>&1`);
	print "Executing '$C_cc $C_ccflags -o $file $in $C_ldflags $C_libs $options 2>&1'\n" if $Verbose;
	my($error)=$?;
	print "Error linking: $error, |$result|\n" if $Verbose;
	unlink($in,$out,$file);
	return (($error || $result ne "")?0:1) unless wantarray;
	($error,$result);
}

=head2 Execute

Takes one or more arguments. The first is a string containing a C program.
Embedded newlines are legal, the text simply being stuffed into a temporary
file. The result is then fed to the C compiler and linker (that compiler and
linker being previously determined by perl's metaconfig script.) and then
executed. Any additional arguments provided are passed to the
compilation/link command. (There is no way to feed arguments to the program
being executed.)

In a scalar context, the return value is either undef, indicating the 
compilation or link failed, or that the executed program returned a nonzero
status. Otherwise, the return value is the text output by the program.

In an array context, an array consisting of three values is returned: the
first value is 0 or 1, 1 if the compile/link succeeded. The second value either
the exist status of the compiler or program, and the third is the output text.

=cut

sub Execute { #Compile, link, and execute.

	my($code,@options) = @_;
	my($options)=join(" ",@options);
	my($file) = "tmp$$";
	my($in,$out) = $file.".c",$file.".o";

	open(F,">$in");
	print F $code;
	close(F);
	print "Executing |$code|\n" if $Verbose;
	my($result) = scalar(`$C_cc $C_ccflags -o $file $in $C_ldflags $C_libs $options 2>&1`);
	print "Executing '$C_cc $C_ccflags -o $file $in $C_ldflags $C_libs $options 2>&1'\n" if $Verbose;
	my($error) = $?;
	unlink($in,$out);
	if(!$error) {
		my($result2) = scalar(`./$file`);
		$error = $?;
		unlink($file);
		return ($error?undef:$result2) unless wantarray;
		print "Executed successfully, status $error, link $result, exec |$result2|\n" if $Verbose;
		(1,$error,$result2);
	} else {
		print "Link failed, status $error, message |$result|\n" if $Verbose;
		return undef unless wantarray;
		(0,$error,$result);
	}
}

=head2 FindHeader

Takes an unlimited number of arguments, consisting of both header names in
the form "header.h", or directory specifications such as "-I/usr/include/bsd".
For each supplied header, FindHeader will attempt to find the complete path.
The return value is an array consisting of all the headers that were located.

=cut

sub FindHeader { #For each supplied header name, find full path
	my(@headers) = grep(!/^-I/,@_);
	my(@I) = grep(/^-I/,@_);
	my($h);
	for $h (@headers) {
		print "Searching for $h... " if $Verbose;
		if($h eq "") {$h=undef; next}
		if( -f $h) {next}
		if( -f $Config{"usrinc"}."/".$h) {
			$h = $Config{"usrinc"}."/".$h;
			print "Found as $h.\n" if $Verbose;
		} else {
			if($text = CPP("#include <$h>",join(" ",@I))) {
				grepcpp:
				for (split(/\s+/,(grep(/^\s*#.*$h/,split(/\n/,$text)))[0])) {
					if(/$h/) {
						s/^\"(.*)\"$/$1/;
						s/^\'(.*)\'$/$1/;					
						$h = $_;
						print "Found as $h.\n" if $Verbose;
						last grepcpp; 
					}
				}
			} else {
				$h = undef; # remove header from resulting list
				print "Not found.\n" if $Verbose;
			}
		}
	}
	grep($_,@headers);
}

=head2 FindLib

Takes an unlimited number of arguments, consisting of both library names in
the form "-llibname", "/usr/lib/libxyz.a" or "dld", or directory
specifications such as "-L/usr/lib/foo". For each supplied library, FindLib
will attempt to find the complete path. The return value is an array
consisting of the full paths to all of the libraries that were located.

=cut

sub FindLib { #For each supplied library name, find full path
	my(@libs) = grep(!/^-L/,@_);
	my(@L) = (grep(/^-L/,@_),split(" ",$Config{"libpth"}));
	grep(s/^-L//,@L);
	my($l);
	my($so) = $Config{"so"};
	my($found);
	#print "Libaries I am searching for: ",join(",",@libs),"\n";
	#print "Directories: ",join(",",@L),"\n";
	for $lib (@libs) {
		print "Searching for $lib... " if $Verbose;
		$found=0;		
		$lib =~ s/^-l//;
		if($lib eq "") {$lib=undef; next}
		next if -f $lib;
		for $path (@L) {
			print "Searching $path for $lib...\n" if $Verbose;
			if (@fullname=<${path}/lib${lib}.${so}.[0-9]*>){
				$fullname=$fullname[-1]; #ATTN: 10 looses against 9!
			} elsif (-f ($fullname="$path/lib$lib.$so")){
			} elsif (-f ($fullname="$path/lib${lib}_s.a")
			&& ($lib .= "_s") ){ # we must explicitly ask for _s version
			} elsif (-f ($fullname="$path/lib$lib.a")){
			} elsif (-f ($fullname="$path/Slib$lib.a")){
			} else { 
				warn "$lib not found in $path\n" if $Verbose;
				next;
			}
			warn "'-l$thislib' found at $fullname\n" if $Verbose;
			$lib = $fullname;
			$found=1;
		}
		if(!$found) { 
			$lib = undef; # Remove lib if not found
			print "Not found.\n" if $Verbose;
		}
	}
	grep($_,@libs);
}


=head2

Apply takes a chunk of code, a series of libraries and headers, and attempts
to apply them, in series, to a given perl command. In a scalar context, the
return value of the first set of headers and libraries that produces a 
non-zero return value from the command is returned. In an array context, the
header and library set it returned.

This is best explained by some examples:

	Apply(\&Compile,"main(){}","sgtty.h",""); 

In a scalar context either C<undef> or C<1>. In an array context,
this returns C<()> or C<("sgtty.h","")>.

	Apply(\&Link,"main(){int i=COLOR_PAIRS;}","curses.h","-lcurses",
	"ncurses.h","-lncurses","ncurses/ncurses.h","-lncurses");

In a scalar context, this returns either C<undef>, C<1>. In an array context,
this returns C<("curses.h","-lcurses")>, C<("ncurses.h","-lncurses")>, 
C<("ncurses/ncurses.h","-lncurses")>, or C<()>.

If we had instead said 
C<Apply(\&Execute,'main(){printf("%d",(int)COLOR_PAIRS)',...)> then in a scalar
context either C<undef> or the value of COLOR_PAIRS would be returned.

Note that you can also supply multiple headers and/or libraries at one time,
like this:

	Apply(\&Compile,"main(){fcntl(0,F_GETFD);}","fcntl.h","",
	"ioctl.h fcntl.h","","sys/ioctl.h fcntl.h"","");

So if fcntl needs ioctl or sys/ioctl loaded first, this will catch it. In an 
array context, C<()>, C<("fcntl.h","")>, C<("ioctl.h fcntl.h","")>, or 
C<("sys/ioctl.h fcntl.h","")> could be returned.

You can also use nested arrays to get exactly the same effect. The returned
array will always consist of a string, though, with elements separated by
spaces.

	Apply(\&Compile,"main(){fcntl(0,F_GETFD);}",["fcntl.h"],"",
	["ioctl.h","fcntl.h"],"",["sys/ioctl.h","fcntl.h"],"");

Note that there are many functions that provide simpler ways of doing these
things, from GetNumericSymbol to get the value of a symbol, to ApplyHeaders
which doesn't ask for libraries.

=cut

sub Apply { #
	my($cmd,$code,@lookup) = @_;
	my(@l,@h,$i,$ret);
	for ($i=0;$i<@lookup;$i+=2) {
		if( ref($lookup[$i]) eq "ARRAY" ) {
			@h = @{$lookup[$i]};
		} else {
			@h = split(/\s+/,$lookup[$i]);
		}
		if( ref($lookup[$i+1]) eq "ARRAY" ) {
			@l = @{$lookup[$i+1]};
		} else {
			@l = split(/\s+/,$lookup[$i+1]);
		}

		if($ret=&{$cmd == \&Link && !@l?\&Compile:$cmd}(join("",map($_?"#include <$_>\n":"",grep(!/^-I/,@h))).
				$code,grep(/^-I/,@h),@l)) {
			print "Ret=|$ret|\n" if $Verbose;
			return $ret unless wantarray;
		return (join(" ",@h),join(" ",@l));
		}
	}
	return 0 unless wantarray;
	();
}

=head2 ApplyHeadersAndLibs

This function takes the same sort of arguments as Apply, it just sends them
directly to Link.

=cut

sub ApplyHeadersAndLibs { #
	my($code,@lookup) = @_;
	Apply \&Link,$code,@lookup;
}

=head2 ApplyHeadersAndLibsAndExecute

This function is similar to Apply and ApplyHeadersAndLibs, but it always
uses Execute.

=cut

sub ApplyHeadersAndLibsAndExecute { #
	my($code,@lookup) = @_;
	Apply \&Execute,$code,@lookup;
}

=head2 ApplyHeaders

If you are only checking headers, and don't need to look at libs, then
you will probably want to use ApplyHeaders. The return value is the same
in a scalar context, but in an array context the returned array will only 
consists of the headers, spread out.

=cut

sub ApplyHeaders {
	my($code,@headers) = @_;
	return scalar(ApplyHeadersAndLibs $code, map(($_,""),@headers))
		unless wantarray;	
	split(/\s+/,(ApplyHeadersAndLibs $code, map(($_,""),@headers))[0]);
}

=head2 ApplyLibs

If you are only checking libraries, and don't need to look at headers, then
you will probably want to use ApplyLibs. The return value is the same
in a scalar context, but in an array context the returned array will only 
consists of the libraries, spread out.

=cut

sub ApplyLibs {
	my($code,@libs) = @_;
	return scalar(ApplyHeadersAndLibs $code, map(("",$_),@libs))
		unless wantarray;	
	split(/\s+/,(ApplyHeadersAndLibs $code, map(("",$_),@libs))[0]);
}

=head2 CheckHeader

Takes an unlimited number of arguments, consiting of headers in the
Apply style. The first set that is fully accepted
by the compiler is returned. 

=cut

sub CheckHeader { #Find a header (or set of headers) that exists
	ApplyHeaders("main(){}",@_);
}

=head2 CheckStructure

Takes the name of a structure, and an unlimited number of further arguments
consisting of header groups. The first group that defines that structure 
properly will be returned. B<undef> will be returned if nothing succeeds.

=cut

sub CheckStructure { # Check existance of a structure.
	my($structname,@headers) = @_;
	ApplyHeaders("main(){ struct $structname s;}",@headers);
}

=head2 CheckField

Takes the name of a structure, the name of a field, and an unlimited number
of further arguments consisting of header groups. The first group that
defines a structure that contains the field will be returned. B<undef> will
be returned if nothing succeeds.

=cut

sub CheckField { # Check for the existance of specified field in structure
	my($structname,$fieldname,@headers) = @_;
	ApplyHeaders("main(){ struct $structname s1; struct $structname s2;
								 s1.$fieldname = s2.$fieldname; }",@headers);
}

=head2 CheckLSymbol

Takes the name of a symbol, and an unlimited number of further arguments
consisting of library groups. The first group of libraries that defines
that symbol will be returned. B<undef> will be returned if nothing succeeds.

=cut

sub CheckLSymbol { # Check for linkable symbol
	my($symbol,@libs) = @_;
	ApplyLibs("main() { void * f = (void *)($symbol); }",@libs);
}

=head2 CheckSymbol

Takes the name of a symbol, and an unlimited number of further arguments
consisting of header and library groups, in the Apply format. The first
group of headers and libraries that defines that symbol will be returned.
B<undef> will be returned if nothing succeeds.

=cut

sub CheckSymbol { # Check for linkable/header symbol
	my($symbol,@lookup) = @_;
	ApplyHeadersAndLibs("main() { void * f = (void *)($symbol); }",@lookup);
}

=head2 CheckHSymbol

Takes the name of a symbol, and an unlimited number of further arguments
consisting of header groups. The first group of headers that defines
that symbol will be returned. B<undef> will be returned if nothing succeeds.

=cut

sub CheckHSymbol { # Check for header symbol
	my($symbol,@headers) = @_;
	ApplyHeaders("main() { void * f = (void *)($symbol); }",@headers);
}

=head2 CheckHPrototype (unexported)

An experimental routine that takes a name of a function, a nested array
consisting of the prototype, and then the normal header groups. It attempts
to deduce whether the given prototype matches what the header supplies.
Basically, it doesn't work. Or maybe it does. I wouldn't reccomend it,
though.

=cut

sub CheckHPrototype { # Check for header prototype.
	# Note: This function is extremely picky about "const int" versus "int",
   # and depends on having an extremely snotty compiler. Anything but GCC
   # may fail, and even GCC may not work properly. In any case, if the
   # names function doesn't exist, this call will _succeed_. Caveat Utilitor.
	my($function,$proto,@headers) = @_;
	my(@proto) = @{$proto};
	ApplyHeaders("main() { extern ".$proto[0]." $function(".
								 join(",",@proto[1..$#proto])."); }",@headers);
}

=head2 GetSymbol

Takes the name of a symbol, a printf command, a cast, and an unlimited
number of further arguments consisting of header and library groups, in the
Apply. The first group of headers and libraries that defines that symbol
will be used to get the contents of the symbol in the format, and return it.
B<undef> will be returned if nothing defines that symbol.

Example:

	GetSymbol("__LINE__","ld","long","","");

=cut

sub GetSymbol { # Check for linkable/header symbol
	my($symbol,$printf,$cast,@lookup) = @_,"","";
	scalar(ApplyHeadersAndLibsAndExecute(
		"main(){ printf(\"\%$printf\",($cast)($symbol));exit(0);}",@lookup));
}

=head2 GetTextSymbol

Takes the name of a symbol, and an unlimited number of further arguments
consisting of header and library groups, in the ApplyHeadersAndLibs format.
The first group of headers and libraries that defines that symbol will be
used to get the contents of the symbol in text format, and return it.
B<undef> will be returned if nothing defines that symbol.

Note that the symbol I<must> actually be text, either a char* or a constant
string. Otherwise, the results are undefined.

=cut

sub GetTextSymbol { # Check for linkable/header symbol
	my($symbol,@lookup) = @_,"","";
	my($result) = GetSymbol($symbol,"s","char*",@lookup);
	$result .= "" if defined($result);
	$result;
}

=head2 GetNumericSymbol

Takes the name of a symbol, and an unlimited number of further arguments
consisting of header and library groups, in the ApplyHeadersAndLibs format.
The first group of headers and libraries that defines that symbol will be
used to get the contents of the symbol in numeric format, and return it.
B<undef> will be returned if nothing defines that symbol.

Note that the symbol I<must> actually be numeric, in a format compatible
with a float. Otherwise, the results are undefined.

=cut

sub GetNumericSymbol { # Check for linkable/header symbol
	my($symbol,@lookup) = @_,"","";
	my($result) = GetSymbol($symbol,"f","float",@lookup);
	$result += 0 if defined($result);
	$result;
}

=head2 GetConstants

Takes a list of header names (possibly including -I directives) and attempts
to grep the specified files for constants, a constant being something #defined
with a name that matches /[A-Z0-9_]+/. Returns the list of names.

=cut

sub GetConstants { # Try to grep constants out of a header
	my(@headers) = @_;
	@headers = FindHeader(@headers);
	local(%seen);
	my(%results);
	map($seen{$_}=1,@headers);
	while(@headers) {
		$_=shift(@headers); 
		next if !defined($_);
		open(SEARCHHEADER,"<$_");
		while(<SEARCHHEADER>) {
			if(/^\s*#\s*define\s+([A-Z_][A-Za-z0-9_]+)\s+/) {
				$results{$1} = 1;
			} elsif(/^\s*#\s*include\s+[<"]?([^">]+)[>"]?/) {
				my(@include) = FindHeader($1);
				@include = grep(!$seen{$_},map(defined($_)?$_:(),@include));
				push(@headers,@include);
				map($seen{$_}=1,@include);
			}
		}
		close(SEARCHHEADER);
	}
	keys %results;
}


=head2 DeducePrototype (unexported)

This one is B<really> experimental. The idea is to figure out some basic
characteristics of the compiler, and then attempt to "feel out" the prototype
of a function. Eventually, it may work. It is guaranteed to be very slow,
and it may simply not be capable of working on some systems.

=cut

$firstdeduce=1;
sub DeducePrototype {
	if($firstdeduce) {
		$firstdeduce=0;
		$checknumber=!Compile("extern int func(int a,int b); 
									 extern int func(int a,int b,int c); 
									 main(){}");
		$checkreturn=!Compile("extern int func(int a,int b); 
									 extern long func(int a,int b); 
									 main(){}");
		$checketc=   !Compile("extern int func(int a,int b); 
									 extern long func(int a,...); 
									 main(){}");
		$checknumberetc=!Compile("extern int func(int a,int b); 
									 extern int func(int a,int b,...); 
									 main(){}");
		$checketcnumber=!Compile("extern int func(int a,int b,int c,...); 
									 extern int func(int a,int b,...); 
									 main(){}");
		$checkargtypes=!Compile("extern int func(int a); 
									 extern int func(long a); 
									 main(){}");
		$checkargsnil=!Compile("extern int func(); 
									 extern int func(int a,int b,int c); 
									 main(){}");
		$checknilargs=!Compile("extern int func(int a,int b,int c); 
									 extern int func(); 
									 main(){}");
		$checkargsniletc=!Compile("extern int func(...); 
									 extern int func(int a,int b,int c); 
									 main(){}");
		$checkniletcargs=!Compile("extern int func(int a,int b,int c); 
									 extern int func(...); 
									 main(){}");

		$checkconst=!Compile("extern int func(const int * a);
										extern int func(int * a);
										main(){ }");

		$checksign=!Compile("extern int func(int a);
										extern int func(unsigned int a);
										main(){ }");

		$checkreturnnil=!Compile("extern func(int a);
										extern void func(int a);
										main(){ }");

		@types = sort grep(Compile("main(){$_ a;}"),
			"void","int","long int","unsigned int","unsigned long int","long long int",
			"long long","unsigned long long",
			"unsigned long long int","float","long float",
			"double","long double",
			"char","unsigned char","short int","unsigned short int");

		if(Compile("main(){flurfie a;}")) { @types = (); }

		$Verbose=0;

		# Attempt to remove duplicate types (if any) from type list
		if($checkargtypes) {
			for ($i=0;$i<=$#types;$i++) {
				for ($j=$i+1;$j<=$#types;$j++) {
					next if $j==$i;
					if(Compile("extern void func($types[$i]);
										  extern void func($types[$j]); main(){}")) {
						print "Removing type $types[$j] because it equals $types[$i]\n";
						splice(@types,$j,1);
						$j--;
					}
				}
			}
		} elsif($checkreturn) {
			for ($i=0;$i<=$#types;$i++) {
				for ($j=$i+1;$j<=$#types;$j++) {
					next if $j==$i;
					if(Compile("$types[$i] func(void);
										  extern $types[$j] func(void); main(){}")) {
						print "Removing type $types[$j] because it equals $types[$i]\n";
						splice(@types,$j,1);
						$j--;
					}
				}
			}
		}
		$Verbose=1;

		print "Detect differing numbers of arguments: $checknumber\n";
		print "Detect differing return types: $checkreturn\n";
		print "Detect differing argument types if one is ...: $checketc\n";
		print "Detect differing numbers of arguments if ... is involved: $checknumberetc\n";
		print "Detect differing numbers of arguments if ... is involved #2: $checketcnumber\n";
		print "Detect differing argument types: $checkargtypes\n";
		print "Detect differing argument types if first has no defined args: $checkargsnil\n";
		print "Detect differing argument types if second has no defined args: $checknilargs\n";
		print "Detect differing argument types if first has only ...: $checkargsniletc\n";
		print "Detect differing argument types if second has only ...: $checkniletcargs\n";
		print "Detect differing argument types by constness: $checkconst\n";
		print "Detect differing argument types by signedness: $checksign\n";
		print "Detect differing return types if one is not defined: $checkreturnnil\n";
		print "Types known: ",join(",",@types),"\n";

	}

	my($function,@headers) = @_;
	@headers = CheckHSymbol($function,@headers);
	return undef if !@headers;

	$rettype = undef;
	@args = ();
	@validcount = ();

	# Can we check the return type without worry about arguements?
	if($checkreturn and (!$checknilargs or !$checkniletcargs)) {
		for (@types) {
			if(ApplyHeaders("extern $_ $function(". ($checknilargs?"...":"").");main(){}",[@headers])) {
				$rettype = $_; # Great, we found the return type.
				last;
			}
		}
	}

	if(!defined($rettype) and $checkreturnnil) {
		die "No way to deduce function prototype in a rational amount of time";
	}

	$numargs=-1;
	$varargs=0;
	for (0..32) {
			if(ApplyHeaders("main(){ $function(".join(",",("0") x $_).");}",@headers)) {
				$numargs=$_;
				if(ApplyHeaders("main(){ $function(".join(",",("0") x ($_+1)).");}",@headers)) {
					$varargs=1;
				}
				last
			} 
	}

	die "Unable to deduce number of arguments" if $numargs==-1;

	if($varargs) { $args[$numargs]="..."; }
	
	# OK, now we know how many arguments the thing takes.


	if(@args>0 and !defined($rettype)) {
		for (@types) {
			if(defined(ApplyHeaders("extern $_ $function(".join(",",@args).");main(){}",[@headers]))) {
				$rettype = $_; # Great, we found the return type.
				last;
			}
		}
	}
	
	print "Return type: $rettype\nArguments: ",join(",",@args),"\n";
	print "Valid number of arguments: $numargs\n";
	print "Accepts variable number of args: $varargs\n";
}


#$Verbose=1;

#print scalar(join("|",CheckHeader("sgtty.h"))),"\n";
#print scalar(join("|",FindHeader(CheckHeader("sgtty.h")))),"\n";
#print scalar(join("|",CheckSymbol("COLOR_PAIRS","curses.h","-lcurses","ncurses.h","-lncurses","ncurses/ncurses.h","ncurses/libncurses.a"))),"\n";
#print scalar(join("|",GetNumericSymbol("PRIO_USER","sys/resource.h",""))),"\n";

