FROM ubuntu:latest

RUN apt update && \
    apt install -y youtube-dl awscli && \
    apt clean all