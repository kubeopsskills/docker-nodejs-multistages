# ---- Base Node ----
FROM alpine:3.13.1 AS base

# non-root
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000

ARG BASH_VERSION=5.1.0-r0
ARG NODE_VERSION=15.5.1-r0
ARG NPM_VERSION=14.15.4-r0
ARG TINI_VERSION=0.19.0-r0

RUN export CONTAINER_USER=apprunner && \
    export CONTAINER_GROUP=apprunner && \
    addgroup -g $CONTAINER_GID apprunner && \
    adduser -u $CONTAINER_UID -G apprunner -h /usr/bin/apprunner.d -s /bin/bash -S apprunner

# install node
RUN apk add --no-cache bash=${BASH_VERSION} nodejs-current=${NODE_VERSION} npm=${NPM_VERSION} tini=${TINI_VERSION}
# set working directory
WORKDIR /usr/bin/apprunner.d

# ---- Dependencies ----
FROM base AS dependencies
# copy project file
COPY ./package.json ./package.json
COPY ./package-lock.json ./package-lock.json
# install node packages
RUN npm install --prod
# copy production node_modules aside
RUN cp -R node_modules prod_node_modules

# ---- Builder ----
FROM base AS builder
# copy app sources
COPY ./src ./src
COPY ./tools ./tools
COPY ./services ./services
COPY ./app.config.ts ./app.config.ts
COPY ./moleculer.config.ts ./moleculer.config.ts
COPY ./tsconfig.json ./tsconfig.json
COPY ./package.json ./package.json
COPY ./package-lock.json ./package-lock.json
# install ALL node_modules, including 'devDependencies'
RUN npm install
# build
ENV NODE_ENV production
RUN npm run build

# ---- Test ----
FROM builder AS tester
# copy app sources
COPY ./test ./test
RUN npm ci

# ---- Run ----
FROM base AS runner
# copy production node_modules
COPY --from=dependencies /usr/bin/apprunner.d/prod_node_modules ./node_modules
# copy production built
COPY --from=builder /usr/bin/apprunner.d/dist ./dist

# clean unnecessary files
RUN rm -rf /var/cache/apk/* && rm -rf /tmp/*

# expose port and define CMD
ENV NODE_ENV production
EXPOSE 3000
COPY entrypoint.sh ./entrypoint.sh
RUN chown apprunner:apprunner -R /usr/bin/apprunner.d

USER apprunner
ENTRYPOINT ["/sbin/tini","--","/usr/bin/apprunner.d/entrypoint.sh"]