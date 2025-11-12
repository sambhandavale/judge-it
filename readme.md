# MyJudge: A Secure, Multi-Language Code Execution Engine

MyJudge is a high-performance backend service designed to securely compile and execute untrusted user-submitted code. It is built on a distributed microservice architecture using **Flask**, **Celery**, and **Docker**, ensuring that code execution is both isolated and scalable.  

It is perfect for powering **competitive programming platforms**, **online code editors**, or **e-learning websites**.

---

## Features

- **Secure Sandboxing:** All code is executed within isolated Docker containers with no network access, strict memory/CPU limits, and process restrictions.
- **Asynchronous Processing:** Submissions are handled by a Celery task queue, allowing the API to respond instantly while jobs are processed in the background.
- **Multi-Language Support:** Easily extendable to support any language that can run in a Docker container.
- **Resource Limiting:** Enforces strict execution time (e.g., 2s) and memory (e.g., 256MB) limits for each job.
- **Simple REST API:** Clean API endpoints to submit code and poll for results.

---

## Supported Languages

- **C** (`gcc`)
- **C++** (`g++`)
- **Java** (`eclipse-temurin`)
- **Python** (`python:3.11-slim`)
- **JavaScript** (`node:20-slim`)

---

## Architecture

The system consists of four main services:

1. **Flask API (`app.py`)**  
   Public-facing server to receive submissions, enqueue jobs in Redis, and provide job status endpoints.

2. **Redis**  
   Message broker that holds the queue of pending jobs.

3. **Celery Worker (`worker.py`)**  
   Pulls jobs from Redis, prepares code files, and calls the Docker runner for execution.

4. **Docker Daemon**  
   Spawns isolated containers for each job and ensures resource and security constraints.

### Job Execution Flow

```

[Client]
|

1. POST /run (code, lang, stdin)
   |
   v
   [Flask API]
   |
2. Returns {"task_id": "..."}
   |
3. Enqueues job
   |
   v
   [Redis Queue]
   |
4. Job picked up by Celery Worker
   |
5. Creates temp dir (/tmp/abc)
   |   - code file
   |   - input file
   |
6. Calls Docker daemon
   |
   v
   [Docker]
   |
7. Spawns isolated container (e.g., code_runner_cpp)
   |   - Mounts /tmp/abc as /app
   |   - No network, 256MB RAM, 0.5 CPU
   |   - Executes run.sh
   |
8. run.sh writes output.txt & error.txt
   |
9. Container exits
   |
   v
   [Celery Worker]
   |
10. Reads output/error files
    |
11. Saves result to Redis backend
    |
    [Client]
    |
12. GET /status/<task_id>
    |
13. Fetches result from Redis and returns

````

---

## Getting Started

Run the entire judge system locally using **Docker Compose**.

### Prerequisites

- Docker
- Docker Compose

### 1. Build Runner Images

```bash
docker build -t code_runner_c ./images/c
docker build -t code_runner_cpp ./images/cpp
docker build -t code_runner_java ./images/java
docker build -t code_runner_node ./images/node
docker build -t code_runner_python ./images/python
````

### 2. Run the System

```bash
docker compose up --build
```

This builds the API and worker images and starts all services (`api`, `worker`, `redis`, Docker socket proxy).

---

## API Reference

The API runs at `http://localhost:5000`.

### Submit Code

**Endpoint:** `POST /run`
**Body (JSON):**

```json
{
  "language": "python",
  "source": "print(input())",
  "stdin": "Hello World!"
}
```

**Success Response (202):**

```json
{
  "task_id": "a8f5c01a-6b3d-4c7e-8c0a-9d3f1b0a6e3d",
  "status": "submitted"
}
```

---

### Check Job Status

**Endpoint:** `GET /status/<task_id>`

**Pending Response (200):**

```json
{
  "status": "pending"
}
```

**Success Response (200):**

```json
{
  "return_code": 0,
  "stdout": "Hello World!\n",
  "stderr": "",
  "time": 0.05,
  "status": "SUCCESS"
}
```

**Error Response (200):**

```json
{
  "return_code": 1,
  "stdout": "",
  "stderr": "Runtime Error:\nTraceback (most recent call last):\n  File \"code.py\", line 1, in <module>\n    print(1/0)\nZeroDivisionError: division by zero\n",
  "time": 0.04,
  "status": "SUCCESS"
}
```

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

## License

This project is licensed under the **MIT License**.

```

---

If you want, I can also create a **more visually appealing version with badges, diagrams, and a clean table for supported languages** that would look great on GitHub. Do you want me to do that?
```
