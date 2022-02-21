unit class Net::SMTP:ver<1.2.1>:auth<zef:raku-community-modules>;

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

# vim: expandtab shiftwidth=4
