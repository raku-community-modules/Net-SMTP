role Net::SMTP::Simple;

use Email::Simple;

has $.raw is rw;
has $.hostname is rw;

class X::Net::SMTP is Exception {
    has $.server-response;
    has $.nicename;
    method message {
        return ($.nicename // self.^name) ~ " The server responded with\n" ~ $.server-response;
    }
    method new($response) {
        self.bless(:server-response($response));
    }
}
class X::Net::SMTP::Address is Exception {
    has $.server-response;
    has $.address;
    has $.nicename;
    method message {
        my $address = 'address';
        if $.address.list.elems > 1 {
            $address = 'addresses';
        }
        my $response = ($.nicename // self.^name) ~ " The following $address failed to send:\n"
                        ~ $.address.list.join("\n");
        if $.server-response {
            $response ~= "\nThe server responded with\n"
                          ~ $.server-response;
        }
        return $response;
    }
    method new($response, $address) {
        self.bless(:server-response($response), :$address);
    }
}

class X::Net::SMTP::BadGreeting is X::Net::SMTP { has $.nicename = 'Bad greeting from server: '; };
class X::Net::SMTP::BadHELO is X::Net::SMTP { has $.nicename = 'Unable to successfully HELO: '; };
class X::Net::SMTP::BadFrom is X::Net::SMTP::Address { has $.nicename = 'Bad from address: '; };
class X::Net::SMTP::BadTo is X::Net::SMTP::Address { has $.nicename = 'Bad to address: '; };
class X::Net::SMTP::NoValidTo is X::Net::SMTP::Address { has $.nicename = 'No valid to addresses: '; };
class X::Net::SMTP::BadData is X::Net::SMTP { has $.nicename = 'Unable to enter DATA mode: '; };
class X::Net::SMTP::BadPayload is X::Net::SMTP { has $.nicename = 'Unable to send message: '; };
class X::Net::SMTP::SomeBadTo is X::Net::SMTP::Address { has $.nicename = 'Some to addresses failed to send: '; };

method start {
    $.raw = self.new(:server($.server), :port($.port), :raw, :debug($.debug), :socket-class($.socket-class));
    my $greeting = $.raw.get-response;
    return fail(X::Net::SMTP::BadGreeting.new($greeting)) unless self!check-response($greeting);
    my $helo = $.raw.ehlo($.hostname);
    unless self!check-response($helo, :noquit) {
        # OK, either we can't EHLO, or something is screwy...
        # fall back to HELO
        $helo = $.raw.helo($.hostname);
        return fail(X::Net::SMTP::BadHELO($helo)) unless self!check-response($helo);
    }
    
    # do stuff with $helo here - get auth methods, *

    return True;
}

method auth($username, $password, :$methods, :$disallow) {
    die "Auth NYI - use .raw.send(\"AUTH ...\")";
}

multi method send($from, $to, $message, :$keep-going) {
    my $response = $.raw.mail-from($from);
    return fail(X::Net::SMTP::BadFrom.new($response, $from)) unless self!check-response($response);
    my $to-count;
    my @bad-addresses;
    for $to.list {
        $response = $.raw.rcpt-to($_);
        if $keep-going {
            if self!check-response($response, :noquit) {
                $to-count++;
            } else {
                @bad-addresses.push($_);
            }
        } else {
            return fail(X::Net::SMTP::BadTo.new($response, $_)) unless self!check-response($response);
            $to-count++;
        }
    }
    unless $to-count {
        $.raw.rset;
        return fail(X::Net::SMTP::NoValidTo('', @bad-addresses));
    }
    $response = $.raw.data;
    return fail(X::Net::SMTP::BadData.new($response)) unless self!check-response($response);
    $response = $.raw.payload(~$message);
    return fail(X::Net::SMTP::BadPayload.new($response)) unless self!check-response($response);

    if $keep-going && +@bad-addresses {
        return fail(X::Net::SMTP::SomeBadTo.new('', @bad-addresses)) but True;
    } else {
        return True;
    }
}

multi method send($message, :$keep-going) {
    my $parsed;
    if ($message ~~ Email::Simple) {
        $parsed = $message;
    } else {
        $parsed = Email::Simple.new(~$message);
    }
    my $from = $parsed.header('From');
    my @to = $parsed.header('To');
    @to.push($parsed.header('CC').list);
    @to.push($parsed.header('BCC').list);
    $parsed.header-set('BCC'); # clear the BCC headers

    return self.send($from, @to, $parsed, :$keep-going);
}

method quit {
    $.raw.quit;
    $.raw.conn.close;
    return True;
}

method !check-response($response, :$noquit) {
    if $response.substr(0,1) ne '2'|'3' {
        $.raw.rset unless $noquit;
        return False;
    }
    return True;
}
