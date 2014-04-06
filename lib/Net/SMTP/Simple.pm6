role Net::SMTP::Simple;

has $.raw is rw;
has $.hostname is rw;

method start {
    $.raw = self.new(:server($.server), :port($.port), :raw, :debug($.debug));
    my $greeting = $.raw.get-response;
    return fail "Bad greeting" unless self!check-response($greeting);
    my $helo = $.raw.ehlo($.hostname);
    unless self!check-response($helo, :noquit) {
        # OK, either we can't EHLO, or something is screwy...
        # fall back to HELO
        $helo = $.raw.helo($.hostname);
        return fail "Unable to HELO" unless self!check-response($helo);
    }
    
    # do stuff with $helo here - get auth methods, *

    return True;
}

method auth($username, $password, :$methods, :$disallow) {
    die "Auth NYI - use .raw.send(\"AUTH ...\")";
}

multi method send($from, $to, $message, :$keep-going) {
    my $response = $.raw.mail-from($from);
    return fail "Bad MAIL FROM" unless self!check-response($response);
    my $to-count;
    for $to.list {
        $response = $.raw.rcpt-to($_);
        if $keep-going {
            if self!check-response($response, :noquit) {
                $to-count++;
            } else {
                # push @bad-addresses...
            }
        } else {
            return fail "Bad rcpt-to" unless self!check-response($response);
            $to-count++;
        }
    }
    unless $to-count {
        $.raw.rset;
        return fail "No valid rcpt-to";
    }
    $response = $.raw.data;
    return fail "DATA failed" unless self!check-response($response);
    $response = $.raw.payload(~$message);
    return fail "Message send failed" unless self!check-response($response);

    return True;
}

multi method send($message, :$keep-going) {
    die "Extracting to/from/cc NYI";
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
