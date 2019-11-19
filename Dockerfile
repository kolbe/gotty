FROM ubuntu:18.04 AS mysql-client
RUN sed -i 's/# \(deb-src .*\)$/\1/' /etc/apt/sources.list && \
    apt-get update && \
    apt-get build-dep -y mariadb-client && \
    apt-get install -y \
        git \
        gnutls-dev \
        vim.tiny
RUN    git clone https://github.com/kolbe/mariadb-server --depth=1 --branch=tidb-client /client
WORKDIR /client
RUN    cmake . -DWITHOUT_SERVER=ON
RUN    make -j package && mv mariadb-10.4.*.tar.gz /mariadb.tgz



FROM golang AS gotty
WORKDIR /root
RUN git clone https://github.com/kolbe/gotty
WORKDIR gotty
RUN go build -a -o /



FROM ubuntu:18.04
COPY --from=gotty /gotty /
COPY --from=mysql-client /mariadb.tgz /
RUN apt-get update \
    && apt-get install -y \
       libreadline5 \
       less \
       mysql-client \
       vim.tiny \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /mariadb \
    && tar -C /mariadb --strip-components=1 -xzvf /mariadb.tgz 

ADD client-loop /client-loop
RUN chmod +x /client-loop

EXPOSE 7681

ENTRYPOINT ["/gotty","-w"]
CMD ["/client-loop"]
