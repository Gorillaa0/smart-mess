from fastapi import APIRouter
from models.predictor import predictor_instance
import time

router = APIRouter(tags=["health"])
START_TIME = time.time()

@router.get("/health")
async def health_check():
    uptime = time.time() - START_TIME
    model_status = "loaded" if predictor_instance.model is not None else "baseline_fallback"
    
    return {
        "status": "healthy",
        "uptime_seconds": round(uptime, 2),
        "model_status": model_status
    }
