FROM golang:1.24.5-alpine
WORKDIR /app
COPY . .
RUN go build -o main .
CMD ["./main"]

