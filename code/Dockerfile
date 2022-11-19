#build stage
FROM golang:alpine AS builder
RUN apk add --no-cache git
WORKDIR /go/src/app
COPY . ./
RUN go get -d -v ./...
RUN go build -o /go/src/app main.go

#final stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
RUN mkdir -p /app
WORKDIR /app
COPY --from=builder /go/src/app/main .
COPY templates/ templates/
COPY controllers/ controllers/
COPY db/ db/
COPY models/ models/
COPY routes/ routes/
LABEL Name=aplicacaoweb Version=0.0.1
EXPOSE 8000
CMD [ "/app/main" ]