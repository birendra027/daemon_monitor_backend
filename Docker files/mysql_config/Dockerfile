FROM birendramondal/daemon_monitor:database_v1.0
COPY ./data.sql /docker-entrypoint-initdb.d/
COPY ./my.cnf /etc/my.cnf
EXPOSE 3306