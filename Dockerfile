FROM golang 
LABEL maintainer "noawayer@gmail.com"

ENV GOPATH /go
ENV PATH /usr/local/go/bin:$GOPATH/bin:$PATH
ENV GOROOT_BOOTSTRAP /usr/local/gobootstrap
ENV CGO_ENABLED=0
ENV GO_VERSION 1.11.1
ENV BUILD_DEPS 'bzip2 gcc patch libc6-dev ca-certificates'


COPY enable-fake-time.patch /usr/local/playground/

COPY fake_fs.lst /usr/local/playground/

RUN apt-get update && apt-get install -y ${BUILD_DEPS} --no-install-recommends


RUN cp -R /usr/local/go $GOROOT_BOOTSTRAP
RUN patch /usr/local/go/src/runtime/rt0_nacl_amd64p32.s /usr/local/playground/enable-fake-time.patch
RUN cd /usr/local/go && go run misc/nacl/mkzip.go -p syscall /usr/local/playground/fake_fs.lst src/syscall/fstest_nacl.go

RUN cd /usr/local/go/src && GOOS=nacl GOARCH=amd64p32 ./make.bash --no-clean

COPY . /go/src/github.com/noaway/playground/
RUN cd /go/src/github.com/noaway/playground/ && go install 

COPY ./depend/sel_ldr_x86_64 /usr/local/bin

RUN mkdir /app

RUN cp /go/bin/playground /app
COPY edit.tpl /app
COPY static /app/static
WORKDIR /app

EXPOSE 8080
ENTRYPOINT ["/app/playground"]