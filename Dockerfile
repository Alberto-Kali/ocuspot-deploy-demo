FROM golang:1.24-alpine AS build
WORKDIR /src
COPY go.mod ./
COPY main.go ./
RUN go build -o /out/ocuspot-deploy-demo .

FROM alpine:3.20
RUN adduser -D -H app
USER app
COPY --from=build /out/ocuspot-deploy-demo /usr/local/bin/ocuspot-deploy-demo
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/ocuspot-deploy-demo"]
