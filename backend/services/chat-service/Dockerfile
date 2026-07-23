# Build de contexto = backend/ (ver docker-compose.yml: context ".").
FROM node:20-alpine AS build
WORKDIR /app

COPY package.json package-lock.json* ./
COPY packages/shared ./packages/shared
COPY services/chat-service ./services/chat-service

RUN npm install --workspace=@asocia/shared --workspace=@asocia/chat-service --include-workspace-root
RUN npm run build --workspace=@asocia/shared
RUN npm run build --workspace=@asocia/chat-service

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/packages/shared ./packages/shared
COPY --from=build /app/services/chat-service ./services/chat-service

WORKDIR /app/services/chat-service
EXPOSE 4002
CMD ["node", "dist/index.js"]
