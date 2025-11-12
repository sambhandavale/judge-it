FROM node:20-slim

# Create a non-root user
RUN groupadd -r runner && useradd -r -g runner runner

# 1. Use /runner as the internal working dir
WORKDIR /runner 

# 2. Copy the script to /runner
COPY run.sh /runner/run.sh
RUN chmod +x /runner/run.sh

# 3. Change ownership of the WORKDIR to the runner user
#    (Good practice, though not strictly needed for this script)
RUN chown -R runner:runner /runner

# 4. Set the user
USER runner

# 5. Point to the script in its new, safe location
ENTRYPOINT ["/runner/run.sh"]