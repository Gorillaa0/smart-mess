import pandas as pd
import numpy as np
import os
import joblib
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from typing import Dict, Any

MODEL_DIR = os.path.join(os.path.dirname(__file__), '..', 'model')

def generate_synthetic_data(n_samples: int = 500) -> pd.DataFrame:
    np.random.seed(42)
    dates = pd.date_range(start='2025-01-01', periods=n_samples, freq='D')
    
    data = []
    for date in dates:
        day_of_week = date.dayofweek
        # Vary student counts to match real mess scales (150-250 students per mess)
        total_active_students = np.random.randint(150, 250)
        mess_off_count = np.random.randint(5, int(total_active_students * 0.20))
        is_exam_day = np.random.choice([True, False], p=[0.1, 0.9])
        is_holiday = np.random.choice([True, False], p=[0.1, 0.9])
        is_special_event = np.random.choice([True, False], p=[0.05, 0.95])
        
        event_impact = np.random.choice(['none', 'low', 'medium', 'high'])
        event_impact_encoded = {'none': 0, 'low': 1, 'medium': 2, 'high': 3}[event_impact]
        
        hostel_occupancy_rate = np.random.uniform(0.75, 1.0)
        
        for meal in ['breakfast', 'lunch', 'dinner']:
            meal_type_encoded = {'breakfast': 0, 'lunch': 1, 'dinner': 2}[meal]
            
            base_attendance = total_active_students - mess_off_count
            
            # Meal-type adjustment: breakfast lowest, lunch highest
            meal_factor = {'breakfast': 0.72, 'lunch': 0.96, 'dinner': 0.85}[meal]
            base_attendance *= meal_factor
                
            if day_of_week >= 5:  # Weekend
                if meal == 'breakfast':
                    base_attendance *= 0.78
                elif meal == 'lunch':
                    base_attendance *= 1.08
            
            if is_exam_day:
                base_attendance *= 0.88
            if is_holiday:
                base_attendance *= 0.55
                
            if is_special_event and meal == 'dinner':
                base_attendance *= 1.15
                
            actual_attendance = int(np.clip(base_attendance * np.random.uniform(0.92, 1.08), 0, total_active_students))
            
            # Historical avg is close to actual (realistic: average of last 30 days)
            historical_avg_attendance = actual_attendance * np.random.uniform(0.93, 1.07)
            historical_avg_wastage = actual_attendance * np.random.uniform(0.02, 0.08)
            prev_day_attendance = int(actual_attendance * np.random.uniform(0.88, 1.12))
            
            data.append({
                'day_of_week': day_of_week,
                'total_active_students': total_active_students,
                'mess_off_count': mess_off_count,
                'is_exam_day': int(is_exam_day),
                'is_holiday': int(is_holiday),
                'is_special_event': int(is_special_event),
                'event_impact_encoded': event_impact_encoded,
                'historical_avg_attendance': historical_avg_attendance,
                'historical_avg_wastage': historical_avg_wastage,
                'prev_day_attendance': prev_day_attendance,
                'hostel_occupancy_rate': hostel_occupancy_rate,
                'meal_type_encoded': meal_type_encoded,
                'actual_attendance': actual_attendance
            })
            
    return pd.DataFrame(data)

def train_model(data: pd.DataFrame) -> RandomForestRegressor:
    X = data.drop('actual_attendance', axis=1)
    y = data['actual_attendance']
    model = RandomForestRegressor(n_estimators=100, random_state=42)
    model.fit(X, y)
    return model

def evaluate_model(model: RandomForestRegressor, X_test: pd.DataFrame, y_test: pd.Series) -> Dict[str, Any]:
    preds = model.predict(X_test)
    rmse = np.sqrt(mean_squared_error(y_test, preds))
    mae = mean_absolute_error(y_test, preds)
    r2 = r2_score(y_test, preds)
    
    acc_5_percent = np.mean(np.abs((preds - y_test) / (y_test + 1e-5)) <= 0.05)
    
    return {
        "rmse": rmse,
        "mae": mae,
        "r2": r2,
        "accuracy_within_5_percent": float(acc_5_percent)
    }

def save_model(model: RandomForestRegressor, path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    joblib.dump(model, path)

def load_model(path: str) -> RandomForestRegressor:
    return joblib.load(path)

def get_feature_importance(model: RandomForestRegressor, feature_names: list) -> Dict[str, float]:
    return dict(zip(feature_names, model.feature_importances_))

if __name__ == '__main__':
    print("Generating synthetic data...")
    df = generate_synthetic_data(1000)
    print("Training model...")
    model = train_model(df)
    
    save_path = os.path.join(MODEL_DIR, 'trained_model.pkl')
    print(f"Saving model to {save_path}...")
    save_model(model, save_path)
    print("Model trained and saved successfully.")
