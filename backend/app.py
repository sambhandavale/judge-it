from flask import Flask, request, jsonify
from worker import run_code_task

app = Flask(__name__)

@app.route("/run", methods=["POST"])
def run_code():
    data = request.json
    lang = data.get("language")
    code = data.get("source")
    stdin = data.get("stdin", "")

    task = run_code_task.delay(lang, code, stdin)
    return jsonify({"task_id": task.id, "status": "submitted"}), 202

@app.route("/status/<task_id>")
def check_status(task_id):
    task = run_code_task.AsyncResult(task_id)
    if task.state == "PENDING":
        return jsonify({"status": "pending"})
    elif task.state == "SUCCESS":
        return jsonify(task.result)
    else:
        return jsonify({"status": task.state, "info": str(task.info)})
