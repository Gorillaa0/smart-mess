import os
import json
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import health, prediction
import uvicorn
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Smart Mess ML API", description="Prediction service for mess attendance")

# Allow origins from env (comma-separated) — defaults to Firebase Hosting domain
_raw_origins = os.environ.get("ALLOWED_ORIGINS", "https://smart-mess-sih.web.app,https://smart-mess-sih.firebaseapp.com,http://localhost:5173,http://localhost:8081")
allow_origins = [o.strip() for o in _raw_origins.split(",")]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(prediction.router)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
