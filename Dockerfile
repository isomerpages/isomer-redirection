FROM staticfloat/nginx-certbot@sha256:dc44e313c7a88df5cb4d7795d718f69a275d68ea4ca9b2fd8aa0984384bb7b90

# Copy over nginx config files
COPY ./nginx.conf /etc/nginx/nginx.conf

# Copy over redirecting configuration
COPY ./https_www_redirects.conf /etc/nginx/conf.d/https_www_redirects.conf
COPY ./domain_redirects.conf /etc/nginx/conf.d/domain_redirects.conf

COPY ./letsencrypt /etc/nginx/user.conf.d

# Remove the default nginx config
RUN rm -f /etc/nginx/conf.d/default.conf

COPY ./entrypoint.sh /scripts/entrypoint.sh
COPY ./poll_certbot.sh /scripts/poll_certbot.sh

# Allow HTTP and HTTPS
EXPOSE 80 443

