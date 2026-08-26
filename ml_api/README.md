# Smart Mess ML API

FastAPI prediction service for estimating college mess attendance.

## Setup
1. Create virtual environment: `python -m venv venv`
2. Activate it: `venv\Scripts\activate` (Windows) or `source venv/bin/activate` (Linux/Mac)
3. Install dependencies: `pip install -r requirements.txt`
4. Run server: `python start.py`

## Endpoints
- `GET /health` - Health status
- `POST /predict` - Main prediction endpoint
- `POST /predict/baseline` - Fallback baseline rule-based prediction
- `POST /model/train` - Retrain the model
- `GET /model/accuracy` - Get model metrics
