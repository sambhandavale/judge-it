# Base image can vary per language, example for C++:
FROM gcc:12.2.0-bullseye

# Create a non-root user (optional but safer)
RUN groupadd -r runner && useradd -r -g runner runner

# Working directory inside container
WORKDIR /runner

# Copy universal runner script
COPY run.sh /runner/run.sh
RUN chmod +x /runner/run.sh

# Run as root so all chmod + execution works
USER root

# Entrypoint to universal script
ENTRYPOINT ["/runner/run.sh"]
