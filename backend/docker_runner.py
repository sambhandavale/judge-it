import subprocess, uuid, os

def run_in_docker(image, workdir, timeout_sec=5):
    container_name = f"judge-{uuid.uuid4().hex[:8]}"
    abs_path = os.path.abspath(workdir)
    print(f"\n[DEBUG] Running in Docker:")
    print(f"  Image: {image}")
    print(f"  Workdir (host): {abs_path}")
    print(f"  Container name: {container_name}")
    print(f"  Host files: {os.listdir(abs_path)}")

    cmd = [
        "docker", "run", "--rm",
        "--name", container_name,
        "--network", "none",
        "--memory", "256m",
        "--cpus", "0.5",
        "--pids-limit", "64",
        "--security-opt", "no-new-privileges",
        "--ulimit", "nofile=64:128",
        "--ulimit", "nproc=64:128",
        "--cap-drop=ALL",
        "-v", f"{abs_path}:/app:rw",
        "-w", "/app",
        image
    ]

    print(f"  Docker Command: {' '.join(cmd)}")

    try:
        proc = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout_sec
        )
        print(f"[DEBUG] Return code: {proc.returncode}")
        print(f"[DEBUG] Stdout: {proc.stdout.decode()}")
        print(f"[DEBUG] Stderr: {proc.stderr.decode()}")
        return proc.returncode, proc.stdout.decode(), proc.stderr.decode()
    except subprocess.TimeoutExpired:
        subprocess.run(["docker", "rm", "-f", container_name], stdout=subprocess.DEVNULL)
        return -1, "", "Execution timed out"
