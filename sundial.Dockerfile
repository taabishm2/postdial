FROM ubuntu:22.04

ENV PKG_CONFIG_PATH=/usr/local/grpc/lib/pkgconfig \
    LD_LIBRARY_PATH=/root/Sundial-Private/src/lib:/usr/local/lib:$LD_LIBRARY_PATH \
    PATH=/root/cmake/bin:$PATH \
    MY_INSTALL_DIR=/root/cmake

RUN apt-get update && \
    apt-get install -y libssl-dev software-properties-common wget sudo && \
    add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - && \
    add-apt-repository -y 'deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-4.0 main' && \
    apt-get update && \
    apt-get install -y python3 python3-pip  apt-utils screen nano \
    software-properties-common build-essential gcc g++ clang \
    lldb lld gdb libc++-dev git flex bison libnuma-dev dstat \
    vim htop vagrant curl libjemalloc-dev openjdk-8-jre-headless \
    cgroup-tools python3-pip numactl libgtest-dev build-essential \
    autoconf libtool pkg-config libgflags-dev 

COPY Sundial-Private /root/Sundial-Private


RUN pip3 install --upgrade pip && pip3 install pandas && \ 
    apt update && \
    echo "set number" > ~/.vimrc

# update cmake
RUN cd /root && \
    mkdir -p $MY_INSTALL_DIR && \
    wget -q -O cmake-linux.sh https://github.com/Kitware/CMake/releases/download/v3.19.6/cmake-3.19.6-Linux-x86_64.sh && \
    sudo sh cmake-linux.sh -- --skip-license --prefix=$MY_INSTALL_DIR && \
    rm cmake-linux.sh

# setup a version of jemalloc with profiling enabled
RUN cd /root && \
    git clone https://github.com/jemalloc/jemalloc.git && \
    cd jemalloc && \
    ./autogen.sh --enable-prof && \
    make -j16 && \
    make install

# set up redis
RUN cd /root && \
    git clone https://github.com/redis/redis.git && \
    cd redis && \
    make && \
    cp /root/Sundial-Private/tools/redis.conf ./  && \
    cd /root  && \
    mkdir redis_data/

RUN cd /etc/ld.so.conf.d && \
    echo "/root/Sundial-Private/src/libs/" >> other.conf && \
    echo "/usr/local/lib" >> other.conf && \
    echo "/usr/lib/x86_64-linux-gnu/" >> other.conf && \
    /sbin/ldconfig

# set up gRPC
RUN cd /root && \
    git clone --recurse-submodules -b v1.58.0 --depth 1 --shallow-submodules https://github.com/grpc/grpc && \
    cd grpc && \
    git submodule update --init --recursive

# Install absl
RUN mkdir -p "/root/grpc/third_party/abseil-cpp/cmake/build" && \
    cd "/root/grpc/third_party/abseil-cpp/cmake/build" && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE ../.. && \
    make && \
    make -j30 install

# Install c-ares
RUN mkdir -p "/root/grpc/third_party/cares/cares/cmake/build" && \
    cd "/root/grpc/third_party/cares/cares/cmake/build" && \
    cmake -DCMAKE_BUILD_TYPE=Release ../.. && \
    make && \
    make -j30 install

# Install protobuf
RUN mkdir -p "/root/grpc/third_party/protobuf/cmake/build" && \
    cd "/root/grpc/third_party/protobuf/cmake/build" && \
    cmake -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release ../.. && \
    make && \
    make -j30 install

# Install re2
RUN mkdir -p "/root/grpc/third_party/re2/cmake/build" && \
    cd "/root/grpc/third_party/re2/cmake/build" && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE ../.. && \
    make && \
    make -j30 install

# Install zlib
RUN mkdir -p "/root/grpc/third_party/zlib/cmake/build" && \
    cd "/root/grpc/third_party/zlib/cmake/build" && \
    cmake -DCMAKE_BUILD_TYPE=Release ../.. && \
    make && \
    make -j30 install

# Install gRPC
RUN cd /root/grpc && mkdir -p "cmake/build" && \
    cd cmake/build && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DgRPC_INSTALL=ON \
        -DgRPC_BUILD_TESTS=OFF \
        -DgRPC_CARES_PROVIDER=package \
        -DgRPC_ABSL_PROVIDER=package \
        -DgRPC_PROTOBUF_PROVIDER=package \
        -DgRPC_RE2_PROVIDER=package \
        -DgRPC_SSL_PROVIDER=package \
        -DgRPC_ZLIB_PROVIDER=package \
        ../.. && \
    make && \
    make -j30 install

# Build helloworld example using cmake
RUN mkdir -p "/root/grpc/examples/cpp/helloworld/cmake/build" && \
    cd "/root/grpc/examples/cpp/helloworld/cmake/build" && \
    cmake ../.. && \
    make -j30

RUN cd /root/Sundial-Private && python3 install.py config_local 0 2> /config_local.log

RUN cd /etc/ld.so.conf.d && echo "$/root/Sundial-Private/src/libs/" | sudo tee -a other.conf && \
    echo "/usr/local/lib" | sudo tee -a other.conf && \
    echo "/usr/lib/x86_64-linux-gnu/" | sudo tee -a other.conf && \
    /sbin/ldconfig

RUN cd /root/Sundial-Private && python3 install.py install_local 0 2> /install_local.log
# RUN cd /root/Sundial-Private/src/proto && protoc --grpc_out=../transport/ --plugin=protoc-gen-grpc=`which grpc_cpp_plugin` --cpp_out=../transport sundial.proto
# RUN cd /root/Sundial-Private/src && make 2> /sundial_make.log

# export PKG_CONFIG_PATH=/root/grpc/third_party/re2:/root/grpc/third_party/bloaty/third_party/re2:$PKG_CONFIG_PATH
