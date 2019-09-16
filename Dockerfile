FROM nginx:1.15.3

# Copy over nginx config files
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./https_www_redirects.conf /etc/nginx/https_www_redirects.conf
COPY ./domain_redirects.conf /etc/nginx/domain_redirects.conf

EXPOSE 80