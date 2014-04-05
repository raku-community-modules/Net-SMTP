role Net::SMTP::Raw;

has $.conn is rw;

method get-response() {
    my $line = $.conn.get;
    my $response = $line;
    while $line.substr(3,1) ne ' ' {
        $line = $.conn.get;
        $response ~= "\r\n"~$line;
    }
    return $response;
}

method send($stuff) {
    $.conn.send($stuff ~ "\r\n");
    return self.get-response;
}

method ehlo($hostname = gethostname()) {
    return self.send("EHLO $hostname");
}

method helo($hostname = gethostname()) {
    return self.send("HELO $hostname");
}

method mail-from($address) {
    return self.send("MAIL FROM:$address");
}

method rcpt-to($address) {
    return self.send("RCPT TO:$address");
}

method data() {
    return self.send("DATA");
}

method payload($mail) {
    if $mail.substr(*-2,2) ne "\r\n" {
        return self.send($mail ~ "\r\n.");
    } else {
        return self.send($mail ~ ".");
    }
}

method rset() {
    return self.send("RSET");
}

method quit() {
    return self.send("QUIT");
}
