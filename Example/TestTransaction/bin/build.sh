dropdb rservicebus_test
createdb rservicebus_test

psql -c "CREATE TABLE table1( field1 BIGINT )" rservicebus_test

psql -c "INSERT INTO table1( field1 ) VALUES ( 1 )" rservicebus_test
