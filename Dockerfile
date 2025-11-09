FROM python:3.11-slim

# Environment settings
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=5000

WORKDIR /app

# Install system dependencies required to build some Python packages (e.g. python-Levenshtein)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        libffi-dev \
        libxml2-dev \
        libxslt1-dev \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first to leverage Docker layer caching
COPY requirements.txt /app/requirements.txt

RUN python -m pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r /app/requirements.txt \
    && pip install --no-cache-dir gunicorn

# Copy the rest of the application
COPY . /app

# Create a non-root user and switch to it
RUN groupadd --gid 1000 appuser || true \
    && useradd --uid 1000 --gid 1000 -m appuser || true \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

# Run the Flask app (app.py defines app = Flask(__name__)) using gunicorn
# Note: Dash is bound to the same Flask server in the app, so this serves both.
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app", "--workers", "2", "--threads", "4", "--timeout", "120"]
