# ==============================================================================
# File    : app.py
# Project : face-rec-service (Microservice)
# Purpose : Provides face embedding generation and verification using DeepFace.
# Author  : [Your Name or Team]
# ==============================================================================

from flask import Flask, request, jsonify
from deepface import DeepFace
import numpy as np
import base64
from io import BytesIO
from PIL import Image
import json
import traceback

# ─────────────────────────────────────────────────────────────────────────────
# Application Setup
# ─────────────────────────────────────────────────────────────────────────────
app = Flask(__name__)

# DeepFace configuration
MODEL_NAME = "SFace"                    # Pre-trained face recognition model
DETECTOR_BACKEND = "retinaface"        # Face detection method
DISTANCE_METRIC = "cosine"             # Similarity measure for comparisons

# ─────────────────────────────────────────────────────────────────────────────
# Preload Model at Startup (Improves response time)
# ─────────────────────────────────────────────────────────────────────────────
try:
    print("Loading face recognition model...")
    _ = DeepFace.build_model(MODEL_NAME)
    print("Model loaded successfully.")
except Exception as e:
    print(f"Error loading model on startup: {e}")

# ─────────────────────────────────────────────────────────────────────────────
# Helper Function: Convert Base64 Image → NumPy Array
# ─────────────────────────────────────────────────────────────────────────────
def b64_to_numpy(b64_string):
    if "data:image" in b64_string:
        b64_string = b64_string.split(',')[1]
    img_bytes = base64.b64decode(b64_string)
    pil_img = Image.open(BytesIO(img_bytes)).convert("RGB")
    return np.array(pil_img)

# ─────────────────────────────────────────────────────────────────────────────
# Route: Generate Face Embedding
# Description: Accepts an image, detects a face, and returns a 128-D embedding
# Method: POST
# Endpoint: /generate-embedding
# ─────────────────────────────────────────────────────────────────────────────
@app.route("/generate-embedding", methods=["POST"])
def generate_embedding():
    try:
        if "face" in request.files:
            img_bytes = request.files["face"].read()
            np_img = np.array(Image.open(BytesIO(img_bytes)).convert("RGB"))
        else:
            return jsonify(error="No image file provided."), 400

        embedding_objs = DeepFace.represent(
            img_path=np_img,
            model_name=MODEL_NAME,
            enforce_detection=True,
            detector_backend=DETECTOR_BACKEND
        )
        embedding = embedding_objs[0]['embedding']
        return jsonify(embedding=embedding), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify(error=f"An error occurred: {e}"), 500

# ─────────────────────────────────────────────────────────────────────────────
# Route: Compare Face to Stored Embedding
# Description: Accepts a face image and an existing embedding, returns match result
# Method: POST
# Endpoint: /compare-faces
# ─────────────────────────────────────────────────────────────────────────────
@app.route("/compare-faces", methods=["POST"])
def compare_faces():
    try:
        if "face" not in request.files:
            return jsonify(error="No face image provided for comparison."), 400

        stored_embedding_json = request.form.get("stored_embedding")
        if not stored_embedding_json:
            return jsonify(error="No stored embedding provided."), 400

        # 1. Load new image
        img_bytes = request.files["face"].read()
        np_img_to_verify = np.array(Image.open(BytesIO(img_bytes)).convert("RGB"))

        # 2. Load stored embedding from JSON
        stored_embedding = json.loads(stored_embedding_json)

        # 3. Use DeepFace.verify to perform the comparison
        result = DeepFace.verify(
            img1_path=np_img_to_verify,
            img2_path=stored_embedding,
            model_name=MODEL_NAME,
            detector_backend=DETECTOR_BACKEND,
            distance_metric=DISTANCE_METRIC,
            enforce_detection=True
        )

        is_match = result["verified"]
        print(f"Comparison Result: {result}")
        return jsonify(is_match=is_match), 200

    except ValueError as e:
        return jsonify(error=f"Could not process image: {e}", is_match=False), 400
    except Exception as e:
        traceback.print_exc()
        return jsonify(error=f"An internal error occurred during comparison: {e}", is_match=False), 500

# ─────────────────────────────────────────────────────────────────────────────
# Server Entry Point
# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
