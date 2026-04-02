ARG POSTGRES_VERSION=18
FROM postgres:${POSTGRES_VERSION}

# Vietnamese locale + pgvector
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl sudo \
       locales postgresql-18-pgvector \
    && sed -i '/vi_VN.UTF-8/s/^# //' /etc/locale.gen \
    && locale-gen vi_VN.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# WAL archive directory
RUN mkdir -p /backups/wal && chown postgres:postgres /backups/wal

# Allow the postgres user to execute certain commands as root without a password
RUN echo "postgres ALL=(root) NOPASSWD: /usr/bin/mkdir, /bin/chown, /usr/bin/openssl" > /etc/sudoers.d/postgres

# Add init scripts while setting permissions
COPY --chmod=755 ./init-ssl.sh /docker-entrypoint-initdb.d/init-ssl.sh
COPY --chmod=755 ./wrapper.sh /usr/local/bin/wrapper.sh

# Extensions: pg_trgm, unaccent, pgcrypto, vector, pg_stat_statements
COPY init.sql /docker-entrypoint-initdb.d/init.sql

ENTRYPOINT ["wrapper.sh"]
CMD ["postgres", "-p", "5432", "-c", "listen_addresses=*"]