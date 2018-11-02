FROM golang

COPY ./depend/sel_ldr_x86_64 /bin

COPY . /go/src/github.com/noaway/playground/
RUN cd /go/src/github.com/noaway/playground && go install

COPY ./depend/sel_ldr_x86_64 /bin
RUN mkdir /app

RUN cp /go/bin/playground /app
COPY edit.tpl /app
COPY static /app/static
WORKDIR /app


EXPOSE 8080
ENTRYPOINT ["/app/playground"]
