class Net::SMTP;

use Net::SMTP::Raw;
use Net::SMTP::Simple;

has $.server;
has $.port;
has $.debug;
has $.raw;
has $.socket-class;

method new(:$server!, :$port = 25, :$raw, :$debug, :$hostname, :$socket-class = IO::Socket::INET){
    my role debug-connection {
        method send($string){
            my $tmpline = $string.substr(0, *-2);
            note '==> '~$tmpline;
            nextwith($string);
        }
        method get() {
            my $line = callwith();
            note '<== '~$line;
            return $line;
        }
    };
    my $self = self.bless(:$server, :$port, :$debug, :$raw, :$socket-class);
    if $raw {
        $self does Net::SMTP::Raw;
        if $debug {
            $self.conn = $socket-class.new(:host($server), :$port) but debug-connection;
        } else {
            $self.conn = $socket-class.new(:host($server), :$port);
        }
        $self.conn.input-line-separator = "\r\n";
    } else {
        $self does Net::SMTP::Simple;
        $self.hostname = $hostname // gethostname;
        my $started = $self.start;
        unless $started {
            return $started;
        }
    }
    return $self;
}
