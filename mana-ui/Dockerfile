FROM node:22-alpine AS build

WORKDIR /workspace/crm-ui

COPY crm-ui/package.json crm-ui/pnpm-lock.yaml crm-ui/pnpm-workspace.yaml ./
COPY crm-ui/apps/web/package.json apps/web/package.json
COPY crm-ui/apps/server/package.json apps/server/package.json
COPY crm-ui/packages packages

RUN corepack enable && pnpm install --frozen-lockfile

COPY crm-ui/apps apps
COPY crm-ui/scripts scripts

RUN pnpm --filter web build

FROM nginx:1.27-alpine

COPY mana-dist/mana-ui/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /workspace/crm-ui/apps/web/dist /usr/share/nginx/html
