from celery import Celery
import tempfile, os, shutil, uuid
from docker_runner import run_in_docker
import time 

import os
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

celery = Celery("worker", broker=REDIS_URL, backend=REDIS_URL)

LANG_MAP = {
    "cpp": {"image": "code_runner_cpp", "filename": "code.cpp"},
    "c": {"image": "code_runner_c", "filename": "code.c"},
    "python": {"image": "code_runner_python", "filename": "code.py"},
    "java": {"image": "code_runner_java", "filename": "Main.java"},
    "javascript": {"image": "code_runner_node", "filename": "code.js"},
}

@celery.task(bind=True, time_limit=10, soft_time_limit=8)
def run_code_task(self, lang, code, stdin):
    if lang not in LANG_MAP:
        return {"error": "Unsupported language"}

    info = LANG_MAP[lang]
    tmpdir = tempfile.mkdtemp(prefix=f"{uuid.uuid4().hex[:8]}-")
    os.chmod(tmpdir, 0o777)

    print(f"[DEBUG] Running code in language: {lang}")
    print(f"[DEBUG] Temp dir created: {tmpdir}")

    try:
        code_path = os.path.join(tmpdir, info["filename"])
        input_path = os.path.join(tmpdir, "input.txt")

        with open(code_path, "w") as f:
            f.write(code)
        with open(input_path, "w") as f:
            f.write(stdin)

        print("[DEBUG] Temp files before execution:", os.listdir(tmpdir))

        start = time.time()
        rc, _, _ = run_in_docker(info["image"], tmpdir)
        elapsed = round(time.time() - start, 2)

        # --- NEW: Read actual output files ---
        output_path = os.path.join(tmpdir, "output.txt")
        error_path = os.path.join(tmpdir, "error.txt")

        stdout = ""
        stderr = ""

        if os.path.exists(output_path):
            with open(output_path, "r") as f:
                stdout = f.read()
        if os.path.exists(error_path):
            with open(error_path, "r") as f:
                stderr = f.read()

        print("[DEBUG] Output read:", repr(stdout))
        print("[DEBUG] Error read:", repr(stderr))

        return {
            "return_code": rc,
            "stdout": stdout[:5000],
            "stderr": stderr[:5000],
            "time": elapsed
        }

    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)
