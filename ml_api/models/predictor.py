import os
import joblib
import uuid
import datetime
from typing import Optional, Dict
from models.schemas import PredictionRequest, PredictionResponse

class Predictor:
    def __init__(self, model_path: Optional[str] = None):
        self.model_path = model_path or os.environ.get('MODEL_PATH', os.path.join(os.path.dirname(__file__), '..', 'model', 'trained_model.pkl'))
        self.model = self.load_model()
        
    def load_model(self):
        try:
            return joblib.load(self.model_path)
        except Exception as e:
            print(f"Warning: Could not load model from {self.model_path}, using baseline. Error: {e}")
            return None
            
    def baseline_predict(self, request: PredictionRequest) -> int:
        base = request.total_active_students - request.mess_off_count
        day_factor = 1.0
        if request.day_of_week >= 5: # Weekend
            day_factor = 1.05 if request.meal_type == 'lunch' else 0.85
            
        meal_factor = {'breakfast': 0.75, 'lunch': 0.95, 'dinner': 0.85}.get(request.meal_type, 0.85)
        
        if request.is_holiday:
            day_factor *= 0.6
            
        prediction = int(base * day_factor * meal_factor * request.hostel_occupancy_rate)
        return max(0, min(prediction, request.total_active_students))
        
    def predict(self, request: PredictionRequest) -> PredictionResponse:
        baseline = self.baseline_predict(request)
        model_used = 'baseline'
        predicted_val = baseline
        feature_importance: Dict[str, float] = {}
        
        if self.model:
            try:
                event_impact_encoded = {'none': 0, 'low': 1, 'medium': 2, 'high': 3}.get(request.event_impact, 0)
                meal_type_encoded = {'breakfast': 0, 'lunch': 1, 'dinner': 2}.get(request.meal_type, 1)
                
                features = [[
                    request.day_of_week,
                    request.total_active_students,
                    request.mess_off_count,
                    int(request.is_exam_day),
                    int(request.is_holiday),
                    int(request.is_special_event),
                    event_impact_encoded,
                    request.historical_avg_attendance,
                    request.historical_avg_wastage,
                    request.prev_day_attendance,
                    request.hostel_occupancy_rate,
                    meal_type_encoded
                ]]
                
                predicted_val = int(self.model.predict(features)[0])
                model_used = 'random_forest'
                
                feature_names = [
                    'day_of_week', 'total_active_students', 'mess_off_count', 
                    'is_exam_day', 'is_holiday', 'is_special_event', 'event_impact_encoded',
                    'historical_avg_attendance', 'historical_avg_wastage', 'prev_day_attendance',
                    'hostel_occupancy_rate', 'meal_type_encoded'
                ]
                if hasattr(self.model, 'feature_importances_'):
                    feature_importance = dict(zip(feature_names, [float(x) for x in self.model.feature_importances_]))
            except Exception as e:
                print(f"Prediction error using model, falling back to baseline: {e}")
                
        safety_buffer_percent = 0.05
        if request.is_special_event:
            safety_buffer_percent = 0.08
            
        recommended = int(predicted_val * (1.0 + safety_buffer_percent))
        confidence_interval = int(predicted_val * 0.05)
        
        return PredictionResponse(
            predicted_attendance=predicted_val,
            confidence_low=max(0, predicted_val - confidence_interval),
            confidence_high=min(request.total_active_students, predicted_val + confidence_interval),
            recommended_preparation=recommended,
            safety_buffer_percent=safety_buffer_percent * 100,
            baseline_prediction=baseline,
            model_used=model_used,
            feature_importance=feature_importance,
            prediction_id=str(uuid.uuid4()),
            timestamp=datetime.datetime.utcnow().isoformat()
        )

predictor_instance = Predictor()
