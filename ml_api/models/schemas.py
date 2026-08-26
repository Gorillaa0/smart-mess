from pydantic import BaseModel
from typing import Dict

class PredictionRequest(BaseModel):
    meal_type: str  # breakfast/lunch/dinner
    date: str  # YYYY-MM-DD
    day_of_week: int  # 0=Monday, 6=Sunday
    total_active_students: int
    mess_off_count: int
    is_exam_day: bool
    is_holiday: bool
    is_special_event: bool
    event_impact: str  # none/low/medium/high
    historical_avg_attendance: float
    historical_avg_wastage: float
    prev_day_attendance: int
    hostel_occupancy_rate: float  # 0.0 to 1.0

class PredictionResponse(BaseModel):
    predicted_attendance: int
    confidence_low: int
    confidence_high: int
    recommended_preparation: int
    safety_buffer_percent: float
    baseline_prediction: int
    model_used: str  # 'random_forest' or 'baseline'
    feature_importance: Dict[str, float]
    prediction_id: str
    timestamp: str
