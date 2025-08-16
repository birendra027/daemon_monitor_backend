CREATE DATABASE IF NOT EXISTS daemon_monitor;

use daemon_monitor;

CREATE TABLE IF NOT EXISTS DaemonDetails 
( daemon_name varchar(255) DEFAULT NULL, daemon_id varchar(255) 
DEFAULT NULL, daemon_status varchar(255) DEFAULT NULL, 
instance int DEFAULT NULL );

insert into DaemonDetails (daemon_name, daemon_id, daemon_status, instance) values ('filetransfer','4','UP',1);
insert into DaemonDetails (daemon_name, daemon_id, daemon_status, instance) values ('rater','12','UP',5);
insert into DaemonDetails (daemon_name, daemon_id, daemon_status, instance) values ('rerater','14','UP',10);
insert into DaemonDetails (daemon_name, daemon_id, daemon_status, instance) values ('mlog','30','UP',1);