P6-Net-SMTP
===========

    my $client = Net::SMTP.new(:server("your.server.here"), :port(587), :debug, :raw);
    $client.get-response; # 220 your.server.here ...
    $client.ehlo; # 250-STARTTLS\r\n250 ...
    $client.mail-from('from@your.server.here'); # 250 OK
    $client.rcpt-to('to@your.server.here'); # 250 OK
    $client.data; # 354 Enter message
    $client.payload($email); # 250 OK
    $client.quit; # 221 closing connection

Only raw mode is currently implemented. A simple mode is coming soon.

SSL/STARTTLS is not supported at this time.

Note that authentication is not yet directly supported - if you need authentication
you will need to generate the command yourself:

    $client.send("AUTH PLAIN ..."); # 235 Authentication successful
