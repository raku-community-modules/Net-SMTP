[![Actions Status](https://github.com/raku-community-modules/Net-SMTP/actions/workflows/linux.yml/badge.svg)](https://github.com/raku-community-modules/Net-SMTP/actions) [![Actions Status](https://github.com/raku-community-modules/Net-SMTP/actions/workflows/macos.yml/badge.svg)](https://github.com/raku-community-modules/Net-SMTP/actions)

NAME
====

Net::SMTP - A pure Raku implementation of an SMTP client

SYNOPSIS
========

```raku
use Net::SMTP;

# raw interface
my $client = Net::SMTP.new(:server("your.server.here"), :port(587), :debug, :raw);
$client.get-response; # 220 your.server.here ...
$client.ehlo; # 250-STARTTLS\r\n250 ...
$client.mail-from('from@your.server.here'); # 250 OK
$client.rcpt-to('to@your.server.here'); # 250 OK
$client.data; # 354 Enter message
$client.payload($email); # 250 OK
$client.quit; # 221 closing connection

#simple interface
my $client = Net::SMTP.new(:server("your.server.here"), :port(587), :debug);
$client.auth($username, $password);
$client.send($from, @to, $message);
$client.send($message); # find From/To/CC/(BCC)? lines
$client.quit;
```

DESCRIPTION
===========

The `Net::SMTP` distribution includes two different modes of operation for sending emails to an SMTP server: a raw mode (sending raw SMTP commands), and a simple mode (just send this email!).

SIMPLE MODE METHODS
===================

Note that all of these methods should return a true value on success or a Failure object if something goes wrong.

new(:$server!, :$port = 25, :$hostname, :$debug, :$socket, :$ssl, :$starttls, :$plain)>
---------------------------------------------------------------------------------------

Creates a new SMTP client and opens the connection to the server. It takes the following named arguments:

### :server

Named argument `:$server` is required and defines which server to connect to. Note that this does **not** do a MX lookup - if you need to find the MX server, use [Net::DNS](https://raku.land/zef:rbt/Net::DNS) or similar.

### :port

Named argument `:$port` specifies the port number to connect to on the remote server. It defaults to 25.

### :hostname

Named argument `:$hostname` specifies the hostname given to the remote server in the initial HELO or EHLO message. It defaults to `$*KERNEL.hostname`.

### :debug

Named argument `:$debug` specifies whether debugging is to be enabled. When set to a true value, will print the SMTP traffic to stderr. Defaults to `False`.

### :socket

Named argument `:$socket` allows you to specify a class other than `IO::Socket::INET` to be used for network communication. If you pass a defined object, Net::SMTP will assume it is a ready-to-use socket.

### :ssl, :starttls, :plain

By default, this module will use STARTTLS if the server reveals that it is supported, otherwise it uses plain-text communication.

To override this, you can pass one of these named arguments:

  * `:ssl` for an initial SSL connection

  * `:starttls` to force STARTTLS usage

  * `:plain` to disable transport encryption completely

auth-methods
------------

Returns a list of auth methods that are both supported by the server and by this module.

auth-methods-raw
----------------

Returns a raw list of authentication methods supported by the server. Response is a space-seperated string.

auth($username, $password, :@methods, :@disallow, :$force)
----------------------------------------------------------

Authenticates with the SMTP server with the given `$username` and `$password`.

Currently supports CRAM-MD5, LOGIN, PLAIN.

You can set the `:@methods` named argument to explicitly declare which authentication methods you would like to try, in your order of preference. If not set, `:methods` will default to the result of `.auth-methods`.

You can set the `:@disallow` named argument to disable authentication methods from being attempted (to disable the insecure auth types, for example).

You can set the `:$force` named argument with a true value to mean that this module won't check the list of server supported authentication types - it will simply assume the server supports everything. This is possibly useful if you have an SMTP server that doesn't support EHLO, but still supports authentication.

send($from, $to, $message, :$keep-going)
----------------------------------------

Sends an email $message (which can be a Str or something with a Str method) from $from; and to $to (which can be either a single address or a list of addresses). If $keep-going is set to a true value, will attempt to send the message even if sending to one of the recipients fails.

send($message, :$keep-going)
----------------------------

Attempts to extract from and to information from the email headers (using [Email::Simplei](https://raku.land/zef:raku-community-modules/Email::Simple)), and then calls the above send method.

Note that if you pass a `Email::Simple` or `Email::MIME` object, this method will **not** create a new object, it will just use what was given.

quit
----

Closes the connection to the server.

RAW MODE METHODS
================

These methods allow access to low-level SMTP protocol interactions:

  * get-response

  * send($stuff)

  * ehlo($hostname = $*KERNEL.hostname)

  * helo($hostname = $*KERNEL.hostname)

  * starttls

  * switch-to-ssl

  * auth-login($username, $password)

  * auth-plain($username, $password)

  * mail-from($address)

  * rcpt-to($address)

  * data

  * payload($mail)

  * rset

  * quit

AUTHOR
======

Andrew Egeler

Source can be located at: https://github.com/raku-community-modules/Net-SMTP . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2014 - 2021 Andrew Egeler

Copyright 2022, 2024 Raku Community

All files in this repository are licensed under the terms of Create Commons License; for details please see the LICENSE file

