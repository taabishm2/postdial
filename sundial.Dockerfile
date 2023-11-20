FROM ubuntu:22.04

ENV PKG_CONFIG_PATH=/root/grpc/third_party/re2:/root/grpc/third_party/bloaty/third_party/re2:/usr/local/grpc/lib/pkgconfig \
    LD_LIBRARY_PATH=/root/Sundial-Private/src/lib:/usr/local/lib:$LD_LIBRARY_PATH \
    PATH=/root/cmake/bin:$PATH \
    MY_INSTALL_DIR=/root/cmake

COPY Sundial-Private/tools/redis.conf /redis.conf
RUN apt-get update && \
    apt-get install -y libssl-dev software-properties-common wget sudo && \
    add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - && \
    add-apt-repository -y 'deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-4.0 main' && \
    apt-get install -y python3 python3-pip  apt-utils screen nano \
    software-properties-common build-essential gcc g++ clang \
    lldb lld gdb libc++-dev git flex bison libnuma-dev dstat \
    vim htop vagrant curl libjemalloc-dev openjdk-8-jre-headless \
    cgroup-tools python3-pip numactl libgtest-dev build-essential \
    autoconf libtool pkg-config libgflags-dev

# Pip installs
RUN pip3 install --upgrade pip && pip3 install pandas && \ 
    echo "set number" > ~/.vimrc && \
    # update cmake
    cd /root && \
    mkdir -p $MY_INSTALL_DIR && \
    wget -q -O cmake-linux.sh https://github.com/Kitware/CMake/releases/download/v3.19.6/cmake-3.19.6-Linux-x86_64.sh && \
    cd /root && sudo sh cmake-linux.sh -- --skip-license --prefix=$MY_INSTALL_DIR && \
    rm cmake-linux.sh && \
    # setup a version of jemalloc with profiling enabled
    cd /root && \
    git clone https://github.com/jemalloc/jemalloc.git && \
    cd jemalloc && \
    ./autogen.sh --enable-prof && \
    make -j16 && \
    make install && \
    # setup .conf files
    cd /etc/ld.so.conf.d && \
    echo "/root/Sundial-Private/src/libs/" >> other.conf && \
    echo "/usr/local/lib" >> other.conf && \
    echo "/usr/lib/x86_64-linux-gnu/" >> other.conf && \
    /sbin/ldconfig && \
    # set up gRPC
    cd /root && \
    git clone --recurse-submodules -b v1.58.0 --depth 1 --shallow-submodules https://github.com/grpc/grpc && \
    cd grpc && \
    git submodule update --init --recursive && \
    # Install absl
    mkdir -p "/root/grpc/third_party/abseil-cpp/cmake/build" && \
    cd "/root/grpc/third_party/abseil-cpp/cmake/build" && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE ../.. && \
    make && \
    make -j30 install && \
    # Install c-ares
    mkdir -p "/root/grpc/third_party/cares/cares/cmake/build" && \
    cd "/root/grpc/third_party/cares/cares/cmake/build" && \
    cmake -DCMAKE_BUILD_TYPE=Release ../.. && \
    make && \
    make -j30 install && \
    # Install protobuf
    mkdir -p "/root/grpc/third_party/protobuf/cmake/build" && \
    cd "/root/grpc/third_party/protobuf/cmake/build" && \
    cmake -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release ../.. && \
    make && \
    make -j30 install && \
    # Install re2
    mkdir -p "/root/grpc/third_party/re2/cmake/build" && \
    cd "/root/grpc/third_party/re2/cmake/build" && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE ../.. && \
    make && \
    make -j30 install && \
    # Install zlib
    mkdir -p "/root/grpc/third_party/zlib/cmake/build" && \
    cd "/root/grpc/third_party/zlib/cmake/build" && \
    cmake -DCMAKE_BUILD_TYPE=Release ../.. && \
    make && \
    make -j30 install && \
    # Install upb
    cd /root && \
    git clone https://github.com/Microsoft/vcpkg.git && \
    cd vcpkg && \
    ./bootstrap-vcpkg.sh && \
    ./vcpkg integrate install && \
    ./vcpkg install upb && \
    # Install gRPC
    cd /root/grpc && mkdir -p "cmake/build" && \
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
    make -j30 install && \
    # Build helloworld example using cmake
    mkdir -p "/root/grpc/examples/cpp/helloworld/cmake/build" && \
    cd "/root/grpc/examples/cpp/helloworld/cmake/build" && \
    cmake ../.. && \
    make -j30 && \
    # set up redis
    cd /root && \
    git clone https://github.com/redis/redis.git && \
    cd redis && \
    make && \
    cd /root  && \
    mkdir redis_data/

COPY Sundial-Private /root/Sundial-Private

RUN cd "/root/Sundial-Private" && python3 install.py config_local 0 2> /config_local.log && \
    # Setup configs in .conf files
    cd /etc/ld.so.conf.d && echo "$/root/Sundial-Private/src/libs/" | sudo tee -a other.conf && \
    echo "/usr/local/lib" | sudo tee -a other.conf && \
    echo "/usr/lib/x86_64-linux-gnu/" | sudo tee -a other.conf && \
    /sbin/ldconfig && \
    # Setup cpp_redis
    cd /root/Sundial-Private/cpp_redis && \
    mkdir -p build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make && make install && \
    # Fixes path for tacopie
    cp -r /root/Sundial-Private/cpp_redis/tacopie/includes/* /usr/local/include/ && \
    chmod -R a+r /usr/local/include/tacopie && \
    ldconfig

RUN cd /root/Sundial-Private && python3 install.py install_local 0 2> /install_local.log && \
    cd /root/Sundial-Private/src/proto && protoc --grpc_out=. --plugin=protoc-gen-grpc=`which grpc_cpp_plugin` --cpp_out=. postdial.proto && \
    cd /root/Sundial-Private/ && ./compile.sh 2> /sundial_compile.log 
    
# RUN cd /root/Sundial-Private/src && make clean && make