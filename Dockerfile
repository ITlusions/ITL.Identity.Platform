# Single-stage build for MkDocs documentation with nginx 
FROM nginx:1.27-alpine

# Update Alpine packages to latest security patches
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache python3 py3-pip git

# Create non-root user
RUN addgroup -g 1000 -S nginx-user && \
    adduser -u 1000 -D -S -G nginx-user nginx-user

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir --upgrade pip --break-system-packages && \
    pip3 install --no-cache-dir -r requirements.txt --break-system-packages

# Copy documentation source
COPY docs/ docs/
COPY mkdocs.yml .

# Build the documentation directly to nginx html directory
RUN mkdocs build --clean --strict --site-dir /usr/share/nginx/html

# Create necessary directories with proper permissions for nginx
RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx /app/logs && \
    chown -R nginx-user:nginx-user /var/cache/nginx /var/run /var/log/nginx /usr/share/nginx/html /app/logs && \
    touch /app/logs/nginx.pid /app/logs/access.log /app/logs/error.log && \
    chown nginx-user:nginx-user /app/logs/nginx.pid /app/logs/access.log /app/logs/error.log && \
    chmod 755 /app/logs

# Configure nginx for subpath serving and health checks
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Health check endpoint (must come before location / block)
    location = /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Search endpoint - allow access to search index
    location /search/ {
        try_files \$uri \$uri/ =404;
        expires 5m;
        add_header Cache-Control "public";
    }

    # Handle assets and static files with caching
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|map|json)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Disable access to hidden files (files starting with dot) - but allow others
    location ~ /\.[^/]*$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Handle all other requests
    location / {
        try_files \$uri \$uri/ \$uri.html /index.html;

        # Cache HTML files for a short time
        location ~* \.html$ {
            expires 5m;
            add_header Cache-Control "public";
        }
    }
}
EOF

# Configure nginx to run as non-root user
RUN cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Create a custom nginx.conf for non-root operation
COPY <<EOF /etc/nginx/nginx.conf
# Run as non-root user
worker_processes auto;
error_log /app/logs/error.log warn;
pid /app/logs/nginx.pid;

events {
    worker_connections 1024;
    multi_accept on;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log /app/logs/access.log main;

    # Performance optimizations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy;

    # Security headers (these will be added by site config too)
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Include site configurations
    include /etc/nginx/conf.d/*.conf;
}
EOF

# Clean up build dependencies to reduce image size
RUN pip3 uninstall -y pip --break-system-packages || true && \
    apk del git py3-pip && \
    rm -rf /root/.cache /tmp/* /var/cache/apk/* && \
    cd /app && rm -rf docs/ mkdocs.yml requirements.txt

# Switch to non-root user
USER nginx-user

EXPOSE 80

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

# Use nginx-user to run nginx
CMD ["nginx", "-g", "daemon off;"]