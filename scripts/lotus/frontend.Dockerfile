# ---------------------------------------
# Development stage
# ---------------------------------------
FROM node:18.11.0-alpine AS development
WORKDIR /frontend
COPY package*.json yarn.lock tsconfig.json \
    vite.config.ts tsconfig.node.json postcss.config.cjs\
    tailwind.config.cjs ./
RUN yarn config set network-timeout 300000 && \
    yarn install --frozen-lockfile
# Bundle app source
COPY public/ ./public/
COPY src/ ./src/
# ---------------------------------------
# Build stage
# ---------------------------------------
FROM development AS build
RUN yarn run build
# ---------------------------------------
# Production stage
# ---------------------------------------
FROM --platform=linux/amd64 nginx:1.23-alpine AS production
#copy static files to nginx
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /frontend/src/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY custom_nginx.conf /frontend/nginx.conf
COPY ./bootstrap.sh /docker-entrypoint.d/40-nginx-bootstrap.sh
RUN chmod +x /docker-entrypoint.d/40-nginx-bootstrap.sh

# ---------------------------------------
# Run
# ---------------------------------------

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
# ENTRYPOINT [ "/frontend_bootstrap.sh" ]
CMD ["nginx", "-g", "daemon off;"]

# CMD [ "/bin/bash", "-c", "/frontend_bootstrap.sh" ]