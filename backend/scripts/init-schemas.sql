-- Se ejecuta una única vez al crear el contenedor de Postgres (ver
-- docker-compose.yml). Cada microservicio vive en su propio esquema dentro
-- de la misma base de datos "asocia" (en producción, cada uno podría tener
-- su propia base de datos/instancia si el tráfico lo justifica).
CREATE SCHEMA IF NOT EXISTS membership;
CREATE SCHEMA IF NOT EXISTS chat;
CREATE SCHEMA IF NOT EXISTS translation;
