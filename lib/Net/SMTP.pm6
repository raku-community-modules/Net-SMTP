class Net::SMTP;

use Net::SMTP::Raw;
use Net::SMTP::Simple;

has $.server;
has $.port;
has $.debug;
has $.raw;

method new(:$server!, :$port = 25, :$raw, :$debug, :$hostname){
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
    my $self = self.bless(:$server, :$port, :$debug, :$raw);
    if $raw {
        $self does Net::SMTP::Raw;
        if $debug {
            $self.conn = IO::Socket::INET.new(:host($server), :$port) but debug-connection;
        } else {
            $self.conn = IO::Socket::INET.new(:host($server), :$port);
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
