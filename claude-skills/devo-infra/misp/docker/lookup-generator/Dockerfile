FROM python:3.11-slim

LABEL maintainer="Platform Engineering <platform-engineering@devo.com>"
LABEL description="MISP Lookup Generator - Generates mispIndicator lookup from MISP events"

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY create-lookups.py /app/
COPY json2lookups.py /app/
COPY module-devolookup/ /app/module-devolookup/
COPY generate-misp-lookup.sh /app/

# Make scripts executable
RUN chmod +x /app/generate-misp-lookup.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import pymisp; print('OK')" || exit 1

# Run as non-root user
RUN useradd -m -u 1000 misp && chown -R misp:misp /app
USER misp

# Default command
CMD ["/app/generate-misp-lookup.sh"]
