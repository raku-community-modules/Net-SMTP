class Net::SMTP;

use Net::SMTP::Raw;

method new(:$server!, :$port = 25, :$raw, :$debug){
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
    my $self = self.bless();
    if $raw {
        $self does Net::SMTP::Raw;
        if $debug {
            $self.conn = IO::Socket::INET.new(:host($server), :$port) but debug-connection;
        } else {
            $self.conn = IO::Socket::INET.new(:host($server), :$port);
        }
        $self.conn.input-line-separator = "\r\n";
    } else {
        die "Simple mode NYI";
        # $self does Net::SMTP::Simple
    }
    return $self;
}
