FROM golang:1.24-alpine AS build
WORKDIR /src
COPY service/go.mod ./
COPY service/main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/accounts-api .
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build --chown=nonroot:nonroot /out/accounts-api /accounts-api
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/accounts-api"]
