FROM node:20-alpine AS base

RUN apk add --no-cache libc6-compat

RUN corepack enable pnpm

RUN corepack use pnpm@latest

WORKDIR /app

COPY package.json .
COPY pnpm-lock.yaml .

RUN pnpm i --frozen-lockfile

COPY . .

FROM base AS builder

WORKDIR /app

COPY --from=base /app/node_modules ./node_modules

COPY . .

RUN pnpm run build

FROM base AS production

WORKDIR /app

ENV NODE_ENV=production

RUN addgroup -g 1001 -S nodejs \
  && adduser -S nextjs -u 1001 \
  && mkdir .next \
  && chown nextjs:nodejs .next

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

USER nextjs

CMD [ "node","server.js" ]

FROM base AS dev

ENV NODE_ENV=development

WORKDIR /app

COPY --from=base /app/node_modules ./node_modules
COPY . .

CMD ["pnpm", "run", "dev"]