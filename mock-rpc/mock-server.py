from concurrent import futures
import grpc
import postdial_pb2
import postdial_pb2_grpc

class PostdialServicer(postdial_pb2_grpc.PostdialServicer):
    def initSchemaRpc(self, request, context):
        print(f"Received initSchemaRpc\n:{request.schemaString}")
        return postdial_pb2.InitSchemaResponse(message='ACK'  )

def serve():
    server_port = 50051
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    postdial_pb2_grpc.add_PostdialServicer_to_server(PostdialServicer(), server)
    server.add_insecure_port(f'[::]:{server_port}')
    server.start()
    print(f"Listening on port: {server_port}")
    server.wait_for_termination()

if __name__ == '__main__':
    serve()
