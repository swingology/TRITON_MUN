FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server.py .

# Wiki root is mounted at runtime: -v /path/to/wiki:/wiki
ENV WIKI_ROOT=/wiki

# FastMCP runs in stdio mode for MCP transport
CMD ["python", "server.py"]
