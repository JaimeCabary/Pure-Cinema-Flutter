import os
import uvicorn
from dotenv import load_dotenv

load_dotenv()

if __name__ == "__main__":
    port = int(os.getenv("PORT", 3000))
    host = os.getenv("HOST", "0.0.0.0")
    print(f"Starting Pure Cinema FastAPI UV Backend on http://{host}:{port}")
    uvicorn.run("app.main:app", host=host, port=port, reload=True)
