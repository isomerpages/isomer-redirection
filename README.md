## Note: This has now been depreciated. Please refer to https://github.com/opengovsg/isomer-redirection for the latest repo

# Isomer Redirection Service

This repository contains the source code for the Isomer redirection service.

This README is meant for the admins of Isomer. It covers how to configure the redirection service.

## Why do we need this?

There are 2 important DNS records when it comes to hosting a website:
- an A record, which maps to an IPv4 address
- a CNAME record, which maps to a domain name

The existing Singapore government DNS service suffers from the apex domain problem - that is, the apex domain can only be an A (or AAAA) record instead of a CNAME record. This is because of the DNS specification: if a domain name (e.g. `example.gov.sg`) has a CNAME record, no other DNS records can exist on that same domain name. And this is problematic because most of the time, you would want to set MX records on the apex domain to receive emails.

The implication is that the apex domain, `example.gov.sg` must map to an **IP address**. However, most CDN providers provide a **domain name instead of an IP address**, which means that the apex domain cannot be set to the CDN domain name.

While there exist DNS providers that have special DNS records to overcome the apex domain problem (e.g. CNAME flattening, ALIAS, and URL records), our government policy prevents us from delegating `.gov.sg` domains to these external DNS providers.

As such, we have decided to use the `www` subdomain as the canonical domain for Singapore government websites, and host a redirection service for the apex domains.

## How this service works

The redirection service is an NGINX server that does the following three things:
- Redirect requests for **HTTP apex** domains to **HTTPS www** domains, e.g. `http://example.gov.sg` to `https://www.example.gov.sg`
- Redirect requests for **HTTPS apex** domains to **HTTPS www** domains, e.g. `https://example.gov.sg` to `https://www.example.gov.sg`
- Redirect requests for **custom HTTP** domains to **custom HTTPS** domains, e.g. `http://custom-example.gov.sg` to `https://example.gov.sg`

## How to configure - LetsEncrypt

Create the following file named `<example.gov.sg>.conf` under the `letsencrypt/` directory:

```
server {
    listen          443 ssl http2;
    listen          [::]:443 ssl http2;
    server_name     <example.gov.sg>;
    ssl_certificate /etc/letsencrypt/live/<example.gov.sg>/fullchain.pem;
    ssl_certificate_key     /etc/letsencrypt/live/<example.gov.sg>/privkey.pem;
    return          301 https://www.<example.gov.sg>$request_uri;
}

```

If desired, `server_name` may have multiple entries, eg, for agency.gov.sg:

```
server {
    listen          443 ssl http2;
    listen          [::]:443 ssl http2;
    server_name     agency.gov.sg agency.sg www.agency.sg;
    ssl_certificate /etc/letsencrypt/live/agency.gov.sg/fullchain.pem;
    ssl_certificate_key     /etc/letsencrypt/live/agency.gov.sg/privkey.pem;
    return          301 https://www.agency.gov.sg$request_uri;
}

```

The files referred to in `ssl_certificate` and `ssl_certificate_key` will not exist; these will
be created by [certbot](https://certbot.eff.org).

Further information on Isomer's LetsEncrypt integration can be found [here](/LETSENCRYPT.md).

## How to configure - custom certificates

### SSL redirection from https://example.gov.sg to https://www.example.gov.sg

First, upload the relevant `<example.gov.sg>.crt` and `<example.gov.sg>.key` files into the `isomer-ssl` AWS S3 bucket. Please ensure that you use the same file name in the S3 bucket as in the NGINX configuration files.

Next, modify the `https_www_redirects.conf` file to include the new SSL block for the `<example.gov.sg>` as shown below.

```
server {
  listen         443 ssl http2;
  listen         [::]:443 ssl http2;
  server_name   <example.gov.sg>;
  ssl_certificate /ssl/<example.gov.sg>.crt; 
  ssl_certificate_key /ssl/<example.gov.sg>.key;
  return         301 https://www.<example.gov.sg>$request_uri;
}
```

### SSL redirection from http://custom-example.gov.sg to https://www.example.gov.sg

Occasionally, we have received requests from government agencies to redirect users from `custom-example.gov.sg` to `www.example.gov.sg`. We are able to do this via the redirection server - but with one caveat: this redirection cannot be done using HTTPS. For HTTPS redirection, we would need the agency to provide us with a SSL cert for `custom-example.gov.sg`, in which case we would follow the instructions above.

To perform such a redirection, add the following NGINX configuration block in the `http_domain_redirects.conf` file as shown below.

```
if ($host ~ "(custom-example.gov.sg)|(www.custom-example.gov.sg)") {
	return 301 https://www.example.gov.sg/;
}
```

## How to deploy and test

### Deploying a staging version of the redirection service

Make the configuration changes as described in the "How to configure" section, and merge your changes into the staging branch. We use TravisCI to deploy the NGINX configuration onto AWS Elastic Beanstalk.

### Testing the redirection service

You may test the redirection service using Postman by following the instructions in this document ([link](https://docs.google.com/document/d/1iPlRIbtMRkGyQgvBTakd2Wvb1HLZ3vWo-sOywhf8QqE/edit)).

### Deploying the config changes to production

Make a PR and merge into the master branch.

### Rebooting the redirection server

You will occasionally want to reboot the redirection server EC2 instance - this could be to re-run the process of generating a LetsEncrypt certificate. **IMPORTANT**: You want to **reboot** the EC2 instance, and not _rebuild_ the Elastic Beanstalk environment, or [bad things can happen](https://docs.google.com/document/d/1S_oA1dNJCAxptExX-jq2IASBh7me9_mGMe1uZByJyrQ/edit#heading=h.wpjagagq76cg). 

Instructions
- Log into the AWS console with your IAM credentials.
- Go to the _EC2 Dashboard_
- Navigate to the _Instances_ view
- Select the redirection server EC2 instance and click on the _Instance state_ dropdown menu on the top of the page.
- Click on _Reboot instance_

## Future Work

- [] Building a CLI tool to upload SSL cert and key into S3 and update the NGINX config files
- [] Automated testing of the staging redirection service
- [] Update NGINX configuration without having to redeploy to AWS Elastic Beanstalk
- [] Improving reliability of the service
- [] Regular automated testing (weekly?) of the SSL configuration with Qualys SSL Labs API
