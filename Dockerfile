FROM nginx:1.18.0

# Copy over nginx config files
COPY ./nginx.conf /etc/nginx/nginx.conf

# Copy over redirecting configuration
COPY ./https_www_redirects.conf /etc/nginx/conf.d/https_www_redirects.conf
COPY ./domain_redirects.conf /etc/nginx/conf.d/domain_redirects.conf

# Copy over config for fallback port 80 listener
COPY ./fallback.conf /etc/nginx/conf.d/fallback.conf

# Remove the default nginx config
RUN rm -f /etc/nginx/conf.d/default.conf

# Allow HTTP and HTTPS
EXPOSE 80 443
