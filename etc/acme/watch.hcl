log_level = "err"
template {
    source = "/etc/acme/templates/cert.ctmpl"
    destination = "/var/www/ssl/cert.pem"
}
template {
    source = "/etc/acme/templates/privkey.ctmpl"
    destination = "/var/www/ssl/privkey.pem"
}
template {
    source = "/etc/acme/templates/fullchain.ctmpl"
    destination = "/var/www/ssl/fullchain.pem"
}
template {
    source = "/etc/acme/templates/chain.ctmpl"
    destination = "/var/www/ssl/chain.pem"
}
template {
    source = "/etc/acme/templates/challenge-token.ctmpl"
    destination = "/var/www/acme/challenge-token"
    command = "/usr/local/bin/acme generate-challenge-token /var/www/acme/challenge-token /var/www/acme/challenge"
}
