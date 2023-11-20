FROM redis

ENV DEBIAN_FRONTEND=non-interactive
ENV PATH="/root/.local/bin:${PATH}"

RUN export MY_INSTALL_DIR=$HOME/.local && mkdir -p $MY_INSTALL_DIR && export PATH="$MY_INSTALL_DIR/bin:$PATH"

RUN apt-get update && apt-get install -y git cmake build-essential autoconf libtool pkg-config g++ libre2-dev libssl-dev zlib1g-dev

RUN cd /root && git clone --recurse-submodules -b v1.58.0 --depth 1 --shallow-submodules https://github.com/grpc/grpc && \
    cd grpc && mkdir -p cmake/build && cd cmake/build && \
    cmake -DgRPC_INSTALL=ON \
        -DgRPC_BUILD_TESTS=OFF \
        -DCMAKE_INSTALL_PREFIX=$MY_INSTALL_DIR ../.. && \
    cd /root/grpc/cmake/build && make -j 8 && make install