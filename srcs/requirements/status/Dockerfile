
FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY status.py /app/status.py

EXPOSE 8080

CMD ["python3", "/app/status.py"]
