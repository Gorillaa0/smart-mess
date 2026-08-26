import os
import subprocess
import sys

def main():
    print("Initializing Smart Mess ML API...")
    
    print("Training initial model...")
    trainer_path = os.path.join("models", "trainer.py")
    subprocess.run([sys.executable, trainer_path], check=True)
    
    print("Starting FastAPI server...")
    subprocess.run([sys.executable, "main.py"])

if __name__ == "__main__":
    main()
