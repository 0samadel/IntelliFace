# ==============================================================================
# Dockerfile for Face Recognition Microservice (face-rec-service)
# Description : Containerizes the Flask-based face recognition API using DeepFace.
# Base Image  : python:3.9-slim-bullseye
# ==============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# Use a lightweight Python image for efficiency and smaller build size
# ─────────────────────────────────────────────────────────────────────────────
FROM python:3.9-slim-bullseye

# Set the working directory inside the container
WORKDIR /app

# ─────────────────────────────────────────────────────────────────────────────
# Install system dependencies required by OpenCV and other libraries
# libgl1-mesa-glx   → for OpenCV GUI/image operations
# libglib2.0-0      → required by image I/O and deep learning backends
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────────────────────────────────────
# Install Python dependencies listed in requirements.txt
# ─────────────────────────────────────────────────────────────────────────────
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ─────────────────────────────────────────────────────────────────────────────
# Copy the entire application code into the container
# ─────────────────────────────────────────────────────────────────────────────
COPY . .

# Make the startup script executable
RUN chmod +x ./start.sh

# ─────────────────────────────────────────────────────────────────────────────
# Expose the port where the Flask app will run
# Default Flask port for this service is 10000
# ─────────────────────────────────────────────────────────────────────────────
EXPOSE 10000

# ─────────────────────────────────────────────────────────────────────────────
# Define the startup command to run the Flask app using the shell script
# ─────────────────────────────────────────────────────────────────────────────
CMD ["./start.sh"]
