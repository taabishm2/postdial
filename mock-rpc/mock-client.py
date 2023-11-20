import grpc
import postdial_pb2
import postdial_pb2_grpc

def run():
    # Assuming the server is running on localhost at port 50051
    channel = grpc.insecure_channel('localhost:50051')
    stub = postdial_pb2_grpc.PostdialStub(channel)

    schema_string = """
    //size, type, name
    TABLE=MAIN_TABLE
        8,int64_t,KEY
        100,string,F0
        100,string,F1
        100,string,F2
        100,string,F3
        100,string,F4
        100,string,F5
        100,string,F6
        100,string,F7
        100,string,F8
        100,string,F9

    INDEX=MAIN_INDEX
    MAIN_TABLE,0"""

    response = stub.initSchemaRpc(postdial_pb2.InitSchemaRequest(schemaString=schema_string))
    print("initSchemaRpc response: " + response.message)

if __name__ == '__main__':
    run()
