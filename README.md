# Postidial
Postdial integrates PostreSQL with a cloud-based, distributed transaction manager, Sundial. The integration allows users to write queries in Postgres which are executed on the Sundial backend as distributed transactions. This allows execution of large queries on a cluster of machines, achieving significantly greater scalability. 

Postdial disaggregates various SQL query processing steps from Sundial and instead performs them on Postgres. The planner output from Postgres is sent to Sundial over gRPC for execution. The users thus retain the familiar PostgreSQL interface while the queries benefit from distributed mode of execution.

![Postdial architecture](/img/implement.png?raw=true "Postdial architecture") \
Fig 1: Architecture


![Postdial vision](/img/vision.png?raw=true "Postdial vision")\
Fig 2: Vision


![Query execution example](/img/example.png?raw=true "Query execution example")\
Fig 2: Query execution example