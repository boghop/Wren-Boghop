#!/usr/bin/perl -wT

use strict;
$|++;


use lib '../lib/CPAN';

use REST::Client;
use JSON::PP;
use HTML::Entities;
use Encode;
use Data::Dumper;

my $api_url = "http://wren.soupmode.com/api/v1";

my $num_args = $#ARGV + 1;
if ($num_args != 1) {
    print "\nUsage: markup2html.pl markdown-file\n";
    exit;
}
 
my $text_file = $ARGV[0];

my $original_markup;

open(my $fh, "<", $text_file) or die "cannot open $text_file for read: $!";
while ( <$fh> ) {
#    chomp;
    $original_markup .= $_; 
}
close($fh) or warn "close failed: $!";


    my $markup = Encode::decode_utf8($original_markup);

# use this line if the markup file contains extended ascii chars.
# if the markup contains extended ascii chars converted to entities, then do not use this line.
# maybe make it a command line option for this program.
    $markup = HTML::Entities::encode($markup,'^\n^\r\x20-\x25\x27-\x7e');


    my $hash = {
        'submit_type' => "Preview",
        'markup'      => $markup,
        'preview_only_key' => 'anything-can-be-used',
    };

    my $json_input = encode_json $hash;

    my $headers = {
        'Content-type' => 'application/json'
    };

    my $rest = REST::Client->new( {
        host => $api_url,
    } );

    $rest->POST( "/posts" , $json_input , $headers );

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        _create_html_file($json);
    } elsif ( $rc >= 400 and $rc < 500 ) {
         die "$json->{description} $json->{user_message} $json->{system_message}";
    } else  {
         die "Unable to complete request. Invalid response code returned from API. $json->{user_message} $json->{system_message}";
    }


sub modify_date {
    my $date_str = shift; # Mon, 22 Feb 2016

    my @arr = split / /, $date_str;

    return "$arr[2] $arr[1], $arr[3]";

}


sub _create_html_file {
    my $hash_ref = shift;

    print <<HTML;
<html>
<head>
<title>$hash_ref->{title}</title>
<meta charset="UTF-8" /> 
<meta name="generator"          content="" />
<meta name=viewport             content="width=device-width, initial-scale=1">
<style>
a:active,a:hover{text-decoration:underline;color:red}h4,h5{text-align:left}h1,h2,h3,h6{text-align:center}body,h5,h6,html{margin:0}article,h1,h2,h5,h6,html,p,pre code{padding:0}html{height:100%;max-height:100%}img{max-width:100%}body{font-family:Arial,sans-serif;background-color:#fcfcfc;color:#333;font-size:125%;line-height:165%}code,pre{background:#f8f8f8;padding:2px 5px;border:1px solid #ddd}pre code{border:none;white-space:-moz-pre-wrap;white-space:pre-wrap;background:0 0}a{color:#00f;text-decoration:underline}a:visited{color:#c39;text-decoration:underline}b,h1,h3,h4,h5,strong{color:#000}li,ul{margin-bottom:10px}p{margin-top:40px;margin-bottom:40px}blockquote{border-left:1px solid #666;background:#E3F2FD;margin:35px 0 35px .6em;padding:0 0 0 1em}h1{margin:20px 0 0;text-transform:uppercase}h2{margin:10px 0;color:#777;font-style:italic}h3,h4{padding-top:30px}h6{font-weight:400;color:#666}h1,h2,h3,h4,h5,h6{font-size:100%}hr{border:0;height:1px;background:#ddd;width:25%;margin-top:2em;margin-bottom:2em}article{position:relative;max-width:640px;margin:0 auto}.smallscreens{display:none}.home-link{line-height:90%;font-size:85%;text-align:left;width:100%;top:0;left:0;float:left;position:absolute;height:20px;text-transform:lowercase}.home-link a,.home-link a:visited{color:#666;text-decoration:none}.home-link a:hover{color:#000;text-decoration:underline}.sitewide-footer{margin-top:20px;text-align:center}.sitewide-footer a,.sitewide-footer a:visited{color:#666;text-decoration:none}.sitewide-footer a:hover{color:#000;text-decoration:underline}.blacklinks a,.blacklinks a:visited{color:#222;text-decoration:none}.blacklinks a:hover{color:#000;text-decoration:underline}.greylinks a,.greylinks a:visited{color:#666;text-decoration:none}.greylinks a:hover{color:#000;text-decoration:underline}#toc{font-size:.8em;float:right;background:#f0fff0;display:inline;width:12.5em;text-align:left;border:1px solid #ccc;line-height:1.2em;padding-top:.3em;padding-bottom:.3em;margin:1.2em 0 1.2em 1.2em}.toclevel1{margin-left:0}.toclevel2{margin-left:.3em}.toclevel3{margin-left:.6em}.toclevel4{margin-left:.9em}.toclevel5{margin-left:1.2em}\@media only screen and (max-width:45em){article{max-width:95%}body{font-size:130%}ul{padding-left:20px}.home-link{text-align:center}h1{margin-top:30px}}
</style>
</head>
<body>
<article>
<header>
<h1>$hash_ref->{title}</h1>
</header>
$hash_ref->{html}
</article>
</body>
</html>
HTML

}



__END__



test.md

==========


# Test Post - 28Apr2016

Hello **world**

* bullet point one
* bullet point two

Some *emphasis.*

A link to [Perl.org](http://perl.org).


==========


./md2html.pl test.md


==========


returned json:

{
  "status":200,
  "description":"OK",
  "post_type":"article",
  "title":"Test Post - 28Apr2016",
  "slug":"test-post-28apr2016",
  "author":"cawr",
  "created_time":"21:36:20 Z",
  "created_date":"Thu, 28 Apr 2016",
  "word_count":14
  "reading_time":0,
  "toc":0,
  "html":"<p>Hello <strong>world</strong></p>\n\n<ul>\n<li>bullet point one</li>\n<li>bullet point two</li>\n</ul>\n\n<p>Some <em>emphasis.</em></p>\n\n<p>A link to <a href=\"http://perl.org\">Perl.org</a>.</p>\n\n",
}

