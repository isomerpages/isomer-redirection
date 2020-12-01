## Isomer's Integration with LetsEncrypt

### Introduction

Let's Encrypt is a nonprofit Certificate Authority run by the Internet 
Security Research Group (ISRG) that provides free SSL certificates.

Isomer takes advantage of this through:

- KeyCDN and Cloudflare's built-in integration for www and other
  non-root domain names, and;
- Using [certbot](https://certbot.eff.org) for root domain names
  hosted by the redirection server.

This document shall focus on the latter usecase.


### Background and Motivations

Isomer serves web traffic on `www.example.gov.sg`, and 301 redirects 
requests to `example.gov.sg` to the www subdomain. These are served 
over HTTPS by separate services, respectively, a CDN and an EC2 instance 
(the redirection server).

Historically, Isomer users were asked to provide an Extended Validation
certificate for use on both services. Given that this is no longer needed,
Isomer can make use of built-in LetsEncrypt certificate provisioning
found on CDNs. 

The redirection server also needs SSL certificates, and given that it
accounts for less than 0.1% of web traffic coming to Isomer, it makes 
very little sense to allocate resources to manually procure and install
a certificate. Given that LetsEncrypt certificates are free and only
available through automated means, integration with Isomer's redirection
server makes sense.

### Implementation Overview

Eliot Saba (@staticfloat) maintains a Docker image based on nginx,
which incorporates certbot. At runtime, the image runs:

- a bootstrap script that inspects and disables/enables config at 
  `/etc/nginx/user.conf.d/` and `/etc/nginx/conf.d/` if 
  they reference missing SSL files before enabling nginx, and;

- a long-running while loop that does the following both at the start 
  as well once every week:

  - run certbot to obtain certificates for domain names implied by
    `ssl_certificate_key` if the path is of the form 
    `/etc/letsencrypt/live/<domain.gov.sg>/privkey.pem` and the file
    is either missing or expired, and;

  - enable the config once the certificates are obtained by reloading
    nginx, through the use of `kill -HUP`.

Elastic Beanstalk is sensitive to `kill -HUP` being sent to processes 
on initialization, terminating with failure if it detects this happening.
To mitigate this, we override the entrypoint script so that it sleeps for 
ten seconds before spawning a poller script, consisting wholly of the 
aforementioned while loop, so that Elastic Beanstalk is satisfied is 
initialization is complete.

See [staticfloat/docker-nginx-certbot#30](https://github.com/staticfloat/docker-nginx-certbot/issues/30) 
for details of this quirk.

The contact e-mail for these certificates is configured by the env var
`CERTBOT_EMAIL`.

Certifcates are stored in an AWS Elastic File System mounted into the EC2
instance at `/etc/letsencrypt`.

Nginx has been configured to reroute requests for `/.well-known` on port 80 
to certbot's internal web service. This allows certbot to prove to LetsEncrypt
that Isomer has control of the domain that we are requesting a certificate for,
via an [HTTP-01 challenge](https://letsencrypt.org/docs/challenge-types/).

Custom SSL certificates are still supported by adding nginx server config blocks
to `https_www_redirects.conf`

### Further Reading

Further information can be found at the relevant GitHub 
[repository](https://github.com/staticfloat/docker-nginx-certbot).
