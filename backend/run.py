import os
import multiprocessing
import uvicorn
from dotenv import load_dotenv

load_dotenv()

if __name__ == "__main__":
    port = int(os.getenv("PORT", 3000))
    host = os.getenv("HOST", "0.0.0.0")
    
    # Calculate optimal workers for fault tolerance (2 * CPU cores + 1)
    default_workers = max(2, multiprocessing.cpu_count() * 2)
    workers = int(os.getenv("WEB_CONCURRENCY", default_workers))
    is_dev = os.getenv("ENV", "development").lower() == "development"

    print(f"Starting Pure Cinema Production FastAPI Server on http://{host}:{port}")
    print(f"Fault Tolerance Mode: {workers} Uvicorn Workers active (Stateless DB Session Management)")

    if is_dev:
        # Single worker with auto-reload for development
        uvicorn.run("app.main:app", host=host, port=port, reload=True)
    else:
        # Multi-worker process cluster for production fault-tolerance
        uvicorn.run("app.main:app", host=host, port=port, workers=workers)
