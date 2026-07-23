# Build de contexto = backend/ (ver docker-compose.yml: context "."),
# porque este servicio depende del paquete compartido packages/shared.
FROM node:20-alpine AS build
WORKDIR /app

COPY package.json package-lock.json* ./
COPY packages/shared ./packages/shared
COPY services/membership-service ./services/membership-service

RUN npm install --workspace=@asocia/shared --workspace=@asocia/membership-service --include-workspace-root
RUN npm run build --workspace=@asocia/shared
RUN npm run build --workspace=@asocia/membership-service

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/packages/shared ./packages/shared
COPY --from=build /app/services/membership-service ./services/membership-service

WORKDIR /app/services/membership-service
EXPOSE 4001
CMD ["node", "dist/index.js"]
