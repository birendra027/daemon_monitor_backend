FROM birendramondal/daemon_monitor:backend_v1.0
WORKDIR /app
COPY . /app
RUN pip install --upgrade pip
RUN pip install -r requirements.txt --verbose
EXPOSE 5000
RUN apk add --no-cache busybox-extras
RUN apk add --no-cache mysql-client
RUN ls -al /app
CMD ["flask", "run", "--host=0.0.0.0"]