FROM postgres:18-bookworm

# Vietnamese locale + pgvector
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       locales postgresql-18-pgvector \
    && sed -i '/vi_VN.UTF-8/s/^# //' /etc/locale.gen \
    && locale-gen vi_VN.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# WAL archive directory
RUN mkdir -p /backups/wal && chown postgres:postgres /backups/wal

# Extensions: pg_trgm, unaccent, pgcrypto, vector, pg_stat_statements
COPY init.sql /docker-entrypoint-initdb.d/init.sql

COPY conf/postgresql.conf /etc/postgresql/postgresql.conf
COPY conf/pg_hba.conf /etc/postgresql/pg_hba.conf

CMD [ "postgres","-c","config_file=/etc/postgresql/postgresql.conf","-c","hba_file=/etc/postgresql/pg_hba.conf" ]