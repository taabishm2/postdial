FROM grpc

ENV PATH="/root/.local/bin:${PATH}"

COPY ./pregresql /pregresql

RUN apt-get update && apt-get install -y git cmake build-essential autoconf libtool pkg-config g++ libre2-dev libssl-dev zlib1g-dev libicu-dev libreadline-dev bison flex gdb
RUN cd /pregresql/src/grpc && rm -rf cmake && mkdir -p cmake/build && cd cmake/build 
RUN cd /pregresql/src/grpc/cmake/build && cmake ../..
RUN cd /pregresql/src/grpc/cmake/build && make -j 20
RUN adduser postgres && \
    echo 'export LD_LIBRARY_PATH="/pregresql/src/grpc/cmake/build:${LD_LIBRARY_PATH}"' >> /etc/profile && \
    cd /pregresql && ./configure --enable-debug CFLAGS="-g" && make -j 20 && make install && \
    mkdir /usr/local/pgsql/data && chown postgres /usr/local/pgsql/data && \
    cd /pregresql/src/grpc && mkdir -p cmake/build && cd cmake/build && cmake ../.. && make -j 20 && \
    su - postgres -c "/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data" && \
    su - postgres -c "/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l ./postgres.logs start && sleep 5" && \
    su - postgres -c "/usr/local/pgsql/bin/createdb test && /usr/local/pgsql/bin/psql -c 'CREATE TABLE users(name TEXT);' test" && \
    su - postgres -c "/usr/local/pgsql/bin/psql -c \"INSERT INTO users (name) VALUES ('John');\" test" && \
    su - postgres -c "/usr/local/pgsql/bin/psql -c 'SELECT * FROM users' test"

# Run a test query: su - postgres -c "/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l ./postgres.logs start" && su - postgres -c "/usr/local/pgsql/bin/psql -c 'SELECT * FROM users' test"
