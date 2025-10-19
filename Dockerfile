# Multi-stage build for production-ready image

# Stage 1: Base image with Ruby
FROM ruby:3.3.6-slim AS base

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libsqlite3-dev \
    nodejs \
    curl \
    git \
    ffmpeg \
    imagemagick \
    libvips42 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install bundler
RUN gem install bundler -v 2.4.1

# Stage 2: Dependencies
FROM base AS dependencies

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Stage 3: Production
FROM base AS production

# Copy installed gems from dependencies stage
COPY --from=dependencies /usr/local/bundle /usr/local/bundle
COPY --from=dependencies /app/.bundle /app/.bundle

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p tmp/pids tmp/sockets log public/videos public/thumbnails

# Set file permissions
RUN chmod -R 755 /app && \
    chown -R nobody:nogroup /app

# Use non-root user for security
USER nobody

# Expose port
EXPOSE 4567

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:4567/ || exit 1

# Start Puma
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]