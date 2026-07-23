# Build de contexto = backend/ (ver docker-compose.yml: context ".").
FROM node:20-alpine AS build
WORKDIR /app

COPY package.json package-lock.json* ./
COPY packages/shared ./packages/shared
COPY services/api-gateway ./services/api-gateway

RUN npm install --workspace=@asocia/shared --workspace=@asocia/api-gateway --include-workspace-root
RUN npm run build --workspace=@asocia/shared
RUN npm run build --workspace=@asocia/api-gateway

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/packages/shared ./packages/shared
COPY --from=build /app/services/api-gateway ./services/api-gateway

WORKDIR /app/services/api-gateway
EXPOSE 4000
CMD ["node", "dist/index.js"]
