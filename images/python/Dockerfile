FROM python:3.11-slim

WORKDIR /app
RUN mkdir -p /app && chmod 777 /app

COPY run.sh /runner/run.sh
RUN chmod +x /runner/run.sh

ENTRYPOINT ["/runner/run.sh"]
