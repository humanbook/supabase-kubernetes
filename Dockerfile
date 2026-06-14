FROM postgres:18

# Install build deps + apt-available extensions
RUN apt-get update && apt-get install -y \
    build-essential git curl \
    libicu-dev libcurl4-openssl-dev \
    autoconf libtool \
    postgresql-server-dev-$PG_MAJOR \
    postgresql-contrib \
    postgresql-$PG_MAJOR-pgvector \
    postgresql-$PG_MAJOR-cron \
    postgresql-$PG_MAJOR-pgaudit \
    postgresql-$PG_MAJOR-repack \
  && rm -rf /var/lib/apt/lists/*

# pg_graphql - prebuilt deb (arm64)
RUN curl -fsSL https://github.com/supabase/pg_graphql/releases/download/v1.6.1/pg_graphql-v1.6.1-pg18-arm64-linux-gnu.deb -o /tmp/pg_graphql.deb \
  && apt-get install -y /tmp/pg_graphql.deb \
  && rm /tmp/pg_graphql.deb

# pgjwt - pure SQL
RUN git clone --depth 1 https://github.com/michelp/pgjwt.git \
  && cd pgjwt && make install && cd / && rm -rf pgjwt

# wal2json - required by Realtime
RUN git clone --depth 1 https://github.com/eulerto/wal2json.git \
  && cd wal2json && make && make install && cd / && rm -rf wal2json

# pg_net - async HTTP
RUN git clone --depth 1 https://github.com/supabase/pg_net.git \
  && cd pg_net && make && make install && cd / && rm -rf pg_net

# libsodium 1.0.22 from source (Debian Trixie ships 1.0.18, pgsodium needs 1.0.20+)
RUN curl -fsSL https://download.libsodium.org/libsodium/releases/libsodium-1.0.22.tar.gz | tar xz \
  && cd libsodium-1.0.22 && ./configure && make -j$(nproc) && make install \
  && ldconfig && cd / && rm -rf libsodium-1.0.22

# pgsodium
RUN git clone --depth 1 --branch v3.1.11 https://github.com/michelp/pgsodium.git \
  && cd pgsodium && make && make install && cd / && rm -rf pgsodium

# supabase_vault
RUN git clone --depth 1 https://github.com/supabase/vault.git \
  && cd vault && make && make install && cd / && rm -rf vault


RUN git clone --depth 1 https://github.com/HypoPG/hypopg.git \
  && cd hypopg && make && make install && cd / && rm -rf hypopg

# shared_preload_libraries config
RUN echo "shared_preload_libraries = 'pg_net,pg_cron,pg_graphql,pg_stat_statements'" \
    >> /usr/share/postgresql/postgresql.conf.sample
