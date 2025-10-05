# Multi-stage build for MkDocs documentation
FROM python:3.11-slim as builder

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy documentation source
COPY docs/ docs/
COPY mkdocs.yml .

# Build the documentation
RUN mkdocs build --clean --strict

# Production stage with nginx
FROM nginx:1.25-alpine

# Create non-root user
RUN addgroup -g 1000 -S nginx-user && \
    adduser -u 1000 -D -S -G nginx-user nginx-user

# Copy built documentation
COPY --from=builder /app/site /usr/share/nginx/html

# Create necessary directories with proper permissions
RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx && \
    chown -R nginx-user:nginx-user /var/cache/nginx /var/run /var/log/nginx /usr/share/nginx/html

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

# Configure nginx to run as non-root
RUN sed -i 's/^user  nginx;/user  nginx-user;/' /etc/nginx/nginx.conf && \
    sed -i 's|/var/run/nginx.pid|/tmp/nginx.pid|' /etc/nginx/nginx.conf && \
    sed -i 's|/var/log/nginx/access.log|/tmp/access.log|' /etc/nginx/nginx.conf && \
    sed -i 's|/var/log/nginx/error.log|/tmp/error.log|' /etc/nginx/nginx.conf

# Switch to non-root user
USER nginx-user

EXPOSE 80

# Use nginx-user to run nginx
CMD ["nginx", "-g", "daemon off;"]