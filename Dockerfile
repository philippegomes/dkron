FROM golang:1.14-alpine as builder
LABEL maintainer="Victor Castell <victor@victorcastell.com>"

RUN mkdir -p /app
WORKDIR /app

ENV GO111MODULE=on
COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download
RUN apk add build-base

COPY . .
RUN CGO_ENABLED=0 go install ./...

FROM alpine
# JQ Required for prestop hook to remove peer from cluster on pod delete action

RUN set -x \
	&& buildDeps='bash ca-certificates openssl tzdata jq' \
	&& apk add --update $buildDeps \
	&& rm -rf /var/cache/apk/* \
	&& mkdir -p /opt/local/dkron

COPY --chown=0:0 --from=builder /go/bin/dkron* /opt/local/dkron/

EXPOSE 8080 8946 6868

ENV SHELL /bin/bash
WORKDIR /opt/local/dkron

ADD ecs-run /usr/local/bin/
RUN chmod +x /usr/local/bin/ecs-run

ADD docker-entrypoint /opt/local/dkron/
RUN chmod +x /opt/local/dkron/docker-entrypoint

ENTRYPOINT ["/opt/local/dkron/docker-entrypoint"]
CMD ["--help"]
