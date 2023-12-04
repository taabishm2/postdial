import grpc
import postdial_pb2
import postdial_pb2_grpc

def run():
    channel = grpc.insecure_channel('localhost:50051')
    stub = postdial_pb2_grpc.PostdialStub(channel)

    # init_schema call
    columns = [
        postdial_pb2.ColumnDetailRequest(name="colA", size=20, type="CHAR"),
        postdial_pb2.ColumnDetailRequest(name="colB", size=20, type="CHAR"),
        postdial_pb2.ColumnDetailRequest(name="colC", size=20, type="INTEGER")
    ]
    init_schema_request = postdial_pb2.InitSchemaRequest(
        table_name="my_table",
        columns=columns,
        key_column_name="colC"
    )
    stub.InitSchema(init_schema_request)
    print("INIT DONE")

    # run_inserts call
    input_rows = [
        postdial_pb2.StringList(values=["Apple", "Banana", "12345"]),
        postdial_pb2.StringList(values=["Cherry", "Date", "67890"]),
        postdial_pb2.StringList(values=["Elder", "Fig", "24680"])
    ]
    run_inserts_request = postdial_pb2.RunInsertsRequest(
        column_names=["colA", "colB", "colC"],
        input_rows=input_rows
    )
    stub.RunInserts(run_inserts_request)
    print("INSERT DONE")

    stub.RunSelect(postdial_pb2.RunSelectRequest(
        column_names=["colA", "colB", "colC"],
        search_key=67890
    ))
    
    stub.RunSelect(postdial_pb2.RunSelectRequest(
        column_names=["colC", "colB", "colA"],
        search_key=67890
    ))

    stub.RunSelect(postdial_pb2.RunSelectRequest(
        column_names=["colA", "colB", "colC"],
        search_key=12345
    ))
    
    stub.RunSelect(postdial_pb2.RunSelectRequest(
        column_names=["colB"],
        search_key=12345
    ))
    print("SELECT DONE")

if __name__ == '__main__':
    run()
