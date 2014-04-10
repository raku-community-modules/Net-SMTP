P6-Net-SMTP
===========

A pure-perl6 implementation of a SMTP client.

SSL/STARTTLS is not supported at this time, and authentication is planned but NYI.

This module includes two different modes of operation: raw mode (sending raw SMTP
commands), and a simple mode (just send this email!).

## Example Usage ##

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
    $client.auth(...); # NYI
    $client.send($from, @to, $message);
    $client.send($message); # find From/To/CC/(BCC)? lines
    $client.quit;

## Simple mode methods ##

 -  `new(:$server!, :$port = 25, :$hostname, :$debug, :$socket-class)`
    
    Creates a new SMTP client and opens the connection to the server.

    `$server` is required and defines what server to connect to. Note that this
    does not do a MX lookup - if you need to find the MX server, use Net::DNS or
    similar.
    
    `$port` defaults to 25, and defines what port to connect to on the remote
    server.

    `$hostname` defaults to calling `gethostname()`, and determines the hostname
    given to the server in the initial HELO or EHLO message

    `$debug` when set to a true value, will print the SMTP traffic to stderr.

    `$socket-class` allows you to define a class other than IO::Socket::INET to
    be used for network communication.

 -  `auth($username, $password, :$methods, :$disallow)`

    NYI

 -  `send($from, $to, $message, :$keep-going)`

    Sends an email $message (which can be a Str or something with a Str method)
    from $from; and to $to (which can be either a single address or a list of
    addresses). If $keep-going is set, will attempt to send the message even if
    one of the recipients fails.

 -  `quit`

    Closes the connection to the server.

## Raw mode methods ##

 -  `new(:raw, :$server!, :$port = 25, :$debug, :$socket-class)`

    Creates a new SMTP client and opens the connection to the server.

    `$server` is required and defines what server to connect to. Note that this
    does not do a MX lookup - if you need to find the MX server, use Net::DNS or
    similar.
    
    `$port` defaults to 25, and defines what port to connect to on the remote
    server.

    `$debug` when set to a true value, will print the SMTP traffic to stderr.

    `$socket-class` allows you to define a class other than IO::Socket::INET to
    be used for network communication.
    
 -  `get-response`
 -  `send($stuff)`
 -  `ehlo($hostname = gethostname())`
 -  `helo($hostname = gethostname())`
 -  `mail-from($address)`
 -  `rcpt-to($address)`
 -  `data`
 -  `payload($mail)`
 -  `rset`
 -  `quit`
