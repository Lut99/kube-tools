# DOCKERFILE for hello-world Python webserver
#   by Lut99

# Take ubuntu as base
FROM ubuntu:20.04

# Update the mirrors
RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt $(. /etc/os-release && echo $VERSION_CODENAME) main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt $(. /etc/os-release && echo $VERSION_CODENAME)-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt $(. /etc/os-release && echo $VERSION_CODENAME)-security main restricted universe multiverse" >> /etc/apt/sources.list

# Install pip3
RUN apt-get update && apt-get install -y python3-pip && rm -rf /var/lib/apt/lists/*

# Install flask
RUN pip3 install flask

# Copy the executable
COPY ./service-test.py /service-test.py

# Set it as entrypoint, done
EXPOSE 8080
ENTRYPOINT ["/bin/bash", "-c", "FLASK_APP=./service-test.py python3 -m flask run --host 0.0.0.0 --port 8080"]
