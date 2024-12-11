unit class Net::SMTP;

has $.server;
has $.port;
has $.debug;
has $.raw;
has $.socket;

has $.tls;
has $.ssl;
has $.plain;

method new(
  Str  :$server!,
  Int  :$port = 25,
  Bool :$raw,
  Bool :$debug,
  Str  :$hostname,
  Mu   :$socket = IO::Socket::INET,
  Bool :$starttls,
  Bool :$ssl,
  Bool :$plain
){
    my role debug-connection {
        method print($string){
            my $tmpline = $string.substr(0, *-2);
            note '==> '~$tmpline;
            nextwith($string);
        }
        method get() {
            my $line = callwith();
            note '<== '~$line;
            $line
        }
    };
    my $self := self.bless:
      :$server, :$port, :$socket, :tls($starttls), :$ssl,
      :$plain, :$debug, :$raw;

    if $raw {
        use Net::SMTP::Raw;
        $self does Net::SMTP::Raw;
        $self.conn = $socket.defined ?? $socket !! $socket.new(:host($server), :$port);
        $self.conn = $self.conn but debug-connection if $debug;
        $self.conn.nl-in = "\r\n";
    }
    else {
        use Net::SMTP::Simple;
        $self does Net::SMTP::Simple;
        $self.hostname = $hostname // $*KERNEL.hostname();
        my $started = $self.start;
        return $started unless $started;
    }
    $self
}

=begin pod

=head1 NAME

Net::SMTP - A pure Raku implementation of an SMTP client

=head1 SYNOPSIS

=begin code :lang<raku>

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

=end code

=head1 DESCRIPTION

The C<Net::SMTP> distribution includes two different modes of operation
for sending emails to an SMTP server: a raw mode (sending raw SMTP
commands), and a simple mode (just send this email!).

=head1 SIMPLE MODE METHODS

Note that all of these methods should return a true value on success or a Failure
object if something goes wrong.

=head2 new(:$server!, :$port = 25, :$hostname, :$debug, :$socket, :$ssl, :$starttls, :$plain)>

Creates a new SMTP client and opens the connection to the server.  It
takes the following named arguments:

=head3 :server

Named argument C<:$server> is required and defines which server to
connect to. Note that this does B<not> do a MX lookup - if you need
to find the MX server, use L<Net::DNS|https://raku.land/zef:rbt/Net::DNS>
or similar.

=head3 :port

Named argument C<:$port> specifies the port number to connect to on
the remote server.  It defaults to 25.

=head3 :hostname

Named argument C<:$hostname> specifies the hostname given to the
remote server in the initial HELO or EHLO message.  It defaults to
C<$*KERNEL.hostname>.

=head3 :debug

Named argument C<:$debug> specifies whether debugging is to be
enabled.  When set to a true value, will print the SMTP traffic
to stderr.  Defaults to C<False>.

=head3 :socket

Named argument C<:$socket> allows you to specify a class other
than C<IO::Socket::INET> to be used for network communication.
If you pass a defined object, Net::SMTP will assume it is a
ready-to-use socket.

=head3 :ssl, :starttls, :plain

By default, this module will use STARTTLS if the server reveals
that it is supported, otherwise it uses plain-text communication.

To override this, you can pass one of these named arguments:
=item C<:ssl> for an initial SSL connection
=item C<:starttls> to force STARTTLS usage
=item C<:plain> to disable transport encryption completely

=head2 auth-methods

Returns a list of auth methods that are both supported by the
server and by this module.

=head2 auth-methods-raw

Returns a raw list of authentication methods supported by the
server. Response is a space-seperated string.

=head2 auth($username, $password, :@methods, :@disallow, :$force)

Authenticates with the SMTP server with the given C<$username>
and C<$password>.

Currently supports CRAM-MD5, LOGIN, PLAIN.

You can set the C<:@methods> named argument to explicitly declare
which authentication methods you would like to try, in your order
of preference. If not set, C<:methods> will default to the result
of C<.auth-methods>.

You can set the C<:@disallow> named argument to disable
authentication methods from being attempted (to disable the
insecure auth types, for example).

You can set the C<:$force> named argument with a true value to
mean that this module won't check the list of server supported
authentication types - it will simply assume the server supports
everything.  This is possibly useful if you have an SMTP server
that doesn't support EHLO, but still supports authentication.

=head2 send($from, $to, $message, :$keep-going)

Sends an email $message (which can be a Str or something with a
Str method) from $from; and to $to (which can be either a single
address or a list of addresses). If $keep-going is set to a true
value, will attempt to send the message even if sending to one
of the recipients fails.

=head2 send($message, :$keep-going)

Attempts to extract from and to information from the email headers
(using L<Email::Simplei|https://raku.land/zef:raku-community-modules/Email::Simple>),
and then calls the above send method.

Note that if you pass a C<Email::Simple> or C<Email::MIME> object,
this method will B<not> create a new object, it will just use what
was given.

=head2 quit

Closes the connection to the server.

=head1 RAW MODE METHODS

These methods allow access to low-level SMTP protocol interactions:

=item get-response
=item send($stuff)
=item ehlo($hostname = $*KERNEL.hostname)
=item helo($hostname = $*KERNEL.hostname)
=item starttls
=item switch-to-ssl
=item auth-login($username, $password)
=item auth-plain($username, $password)
=item mail-from($address)
=item rcpt-to($address)
=item data
=item payload($mail)
=item rset
=item quit

=head1 AUTHOR

Andrew Egeler

Source can be located at: https://github.com/raku-community-modules/Net-SMTP . Comments and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2014 - 2021 Andrew Egeler

Copyright 2022, 2024 Raku Community

All files in this repository are licensed under the terms of Create Commons License; for details please see the LICENSE file

=end pod

# vim: expandtab shiftwidth=4
