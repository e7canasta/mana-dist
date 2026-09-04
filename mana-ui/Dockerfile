FROM node:22-alpine AS build

WORKDIR /workspace/mana-ui

COPY mana-ui/package.json mana-ui/pnpm-lock.yaml mana-ui/pnpm-workspace.yaml ./
COPY mana-ui/apps/web/package.json apps/web/package.json
COPY mana-ui/apps/server/package.json apps/server/package.json
COPY mana-ui/packages packages

RUN corepack enable && pnpm install --frozen-lockfile

COPY mana-ui/apps apps
COPY mana-ui/scripts scripts

RUN pnpm --filter web build

FROM nginx:1.27-alpine

COPY mana-dist/mana-ui/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /workspace/mana-ui/apps/web/dist /usr/share/nginx/html
