FROM ubuntu:22.04

COPY *.py /root/
COPY postdial.proto /root/

RUN apt-get update && apt-get install -y python3-pip && \
    pip3 install grpcio==1.58.0 grpcio-tools==1.58.0
RUN cd /root && python3 -m grpc_tools.protoc -I./ --python_out=. --grpc_python_out=. postdial.proto

WORKDIR /root

# Build the image using
## docker build . -f mockrpc.Dockerfile -t mockrpc

# Run with .py files mounted
## docker run -v ./mock-client.py:/root/mock-client.py -v ./mock-server.py:/root/mock-server.py --network="host" -it mockrpc bash