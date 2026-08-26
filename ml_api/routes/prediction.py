from fastapi import APIRouter, HTTPException
from models.schemas import PredictionRequest, PredictionResponse
from models.predictor import predictor_instance

router = APIRouter(tags=["prediction"])

@router.post("/predict", response_model=PredictionResponse)
async def get_prediction(request: PredictionRequest):
    try:
        return predictor_instance.predict(request)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/predict/baseline")
async def get_baseline_prediction(request: PredictionRequest):
    try:
        val = predictor_instance.baseline_predict(request)
        return {"baseline_prediction": val}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/model/accuracy")
async def get_model_accuracy():
    if not predictor_instance.model:
        return {"status": "Model not loaded, using baseline"}
    
    return {
        "status": "Model loaded",
        "metrics": {
            "note": "Dynamic evaluation not implemented in this endpoint",
            "model_type": "RandomForestRegressor"
        }
    }

@router.post("/model/train")
async def trigger_training():
    from models.trainer import generate_synthetic_data, train_model, save_model
    import os
    
    try:
        df = generate_synthetic_data(500)
        model = train_model(df)
        path = os.environ.get('MODEL_PATH', os.path.join(os.path.dirname(__file__), '..', 'model', 'trained_model.pkl'))
        save_model(model, path)
        
        predictor_instance.model = predictor_instance.load_model()
        return {"message": "Model trained and reloaded successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Training failed: {e}")
