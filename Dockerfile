# =========================
# Build Stage
# =========================
FROM node:20-alpine AS build

WORKDIR /app

# Copy only dependency files first (better caching)
COPY package.json package-lock.json ./

# Install exact, reproducible dependencies
RUN npm ci --omit=dev

# Copy application source
COPY . .

# Build the production bundle
RUN npm run build


# =========================
# Runtime Stage
# =========================
FROM nginx:1.25-alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy hardened nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy build output
COPY --from=build /app/dist /usr/share/nginx/html

# Run as non-root user (security best practice)
USER nginx

EXPOSE 80

# Healthcheck for container orchestration
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
