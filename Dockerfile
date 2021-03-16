FROM jonasal/nginx-certbot:1.1.0-nginx1.19.7

# Copy over nginx config files
COPY ./nginx.conf /etc/nginx/nginx.conf

# Copy over redirecting configuration
COPY ./https_www_redirects.conf /etc/nginx/conf.d/https_www_redirects.conf
COPY ./domain_redirects.conf /etc/nginx/conf.d/domain_redirects.conf

COPY ./letsencrypt /etc/nginx/conf.d

# Remove the default nginx config
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy a script that causes nginx to sleep for 10 seconds
COPY ./00-sleeper.sh /docker-entrypoint.d/00-sleeper.sh

# Allow HTTP and HTTPS
EXPOSE 80 443

