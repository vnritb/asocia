-- Se ejecuta una única vez al crear el contenedor de MariaDB (ver
-- docker-compose.yml). Cada microservicio usa su propia base de datos.
CREATE DATABASE IF NOT EXISTS membership;
CREATE DATABASE IF NOT EXISTS chat;

GRANT ALL PRIVILEGES ON membership.* TO 'asocia'@'%';
GRANT ALL PRIVILEGES ON chat.* TO 'asocia'@'%';
FLUSH PRIVILEGES;
