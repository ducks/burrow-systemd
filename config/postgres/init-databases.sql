-- This SQL script is used by bootstrap to initialize databases
-- It should be run as the postgres superuser

-- Gitea database
CREATE DATABASE gitea;
CREATE USER gitea WITH PASSWORD '__GITEA_DB_PASSWORD__';
GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;
\c gitea
GRANT ALL ON SCHEMA public TO gitea;

-- Woodpecker database
\c postgres
CREATE DATABASE woodpecker;
CREATE USER woodpecker WITH PASSWORD '__WOODPECKER_DB_PASSWORD__';
GRANT ALL PRIVILEGES ON DATABASE woodpecker TO woodpecker;
\c woodpecker
GRANT ALL ON SCHEMA public TO woodpecker;
