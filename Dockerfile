FROM debian:buster-slim

RUN apt-get update ; \
    apt-get install -y build-essential curl

WORKDIR /bin

RUN curl -sL https://cpanmin.us/ -o cpanm && \
    echo "22b92506243649a73cfb55c5990cedd24cdbb20b15b4530064d2496d94d1642b  /bin/cpanm" | sha256sum -c - && \
    chmod +x cpanm

RUN apt-get install -y perl

#COPY install_
