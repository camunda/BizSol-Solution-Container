#!/bin/bash

# Check if Ollama is already running on the host
OLLAMA_PORT=${OLLAMA_PORT:-11434}
DOCKER_HOST=${DOCKER_HOST:-host.docker.internal}

echo "//> Checking if Ollama is running on ${DOCKER_HOST}:${OLLAMA_PORT}..."

# Use bash built-in /dev/tcp for port checking (works on macOS and Linux)
check_port() {
  timeout 2 bash -c "cat < /dev/null > /dev/tcp/$1/$2" 2>/dev/null
  return $?
}

if check_port "$DOCKER_HOST" "$OLLAMA_PORT"; then
  echo "//> Ollama is already running on the host at ${DOCKER_HOST}:${OLLAMA_PORT}"
  echo "//> Using host Ollama service. Container will stay alive but idle."
  # Keep container alive to satisfy dependencies without starting ollama service
  while true; do sleep 3600; done
fi

echo "//> No Ollama service detected on host. Starting container service..."

  # "llama-guard3:1b" "gpt-oss-safeguard"
# Default models to ensure are present
DEFAULT_MODELS=(
  "gpt-oss"
)

# Allow runtime override via OLLAMA_MODELS env var (comma-separated)
if [ -n "$OLLAMA_MODELS" ]; then
  IFS=',' read -ra MODELS <<< "$OLLAMA_MODELS"
  echo "//> Using models from OLLAMA_MODELS env: ${MODELS[*]}"
else
  MODELS=("${DEFAULT_MODELS[@]}")
fi

# Start Ollama server in the background
ollama serve &

# Detect CPU cores (Linux, macOS, Windows/WSL)
get_cpu_cores() {
  if [ -n "$NUMBER_OF_PROCESSORS" ]; then
    # Windows environment variable (available in WSL and some containers)
    echo "$NUMBER_OF_PROCESSORS"
  elif command -v nproc &>/dev/null; then
    # Linux
    nproc
  elif [ -f /proc/cpuinfo ]; then
    # Linux fallback
    grep -c processor /proc/cpuinfo
  elif command -v sysctl &>/dev/null; then
    # macOS
    sysctl -n hw.ncpu
  elif command -v wmic &>/dev/null; then
    # Windows (Git Bash, MSYS2)
    wmic cpu get NumberOfLogicalProcessors /value 2>/dev/null | grep -oE '[0-9]+' | head -1
  else
    echo 2
  fi
}

# Detect RAM in GB (Linux, macOS, Windows/WSL)
get_ram_gb() {
  if [ -f /proc/meminfo ]; then
    # Linux / WSL
    awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo
  elif command -v sysctl &>/dev/null; then
    # macOS
    sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1/1024/1024/1024}'
  elif command -v wmic &>/dev/null; then
    # Windows (Git Bash, MSYS2)
    wmic ComputerSystem get TotalPhysicalMemory /value 2>/dev/null | grep -oE '[0-9]+' | awk '{printf "%.0f", $1/1024/1024/1024}'
  else
    echo 4
  fi
}

CPU_CORES=$(get_cpu_cores)
RAM_GB=$(get_ram_gb)

# Ensure we have valid numbers
CPU_CORES=${CPU_CORES:-2}
RAM_GB=${RAM_GB:-4}

# Score: higher is better (more cores + more RAM = higher score)
# Score ranges roughly from 4 (1 core, 2GB) to 80+ (16 cores, 64GB)
SCORE=$((CPU_CORES * 2 + RAM_GB))

# Map score to sleep time: better hardware = shorter sleep
# Score >= 32 -> 3s, Score >= 16 -> 6s, else -> 9s
if [ "$SCORE" -ge 32 ]; then
  INIT_SLEEP=3
elif [ "$SCORE" -ge 16 ]; then
  INIT_SLEEP=6
else
  INIT_SLEEP=9
fi

echo "//> Detected ${CPU_CORES} CPU cores, ${RAM_GB}GB RAM (score: ${SCORE}, initial sleep: ${INIT_SLEEP}s)"

# Wait for Ollama to be ready
echo "//> Waiting for Ollama to start..."
sleep $INIT_SLEEP
until ollama list > /dev/null 2>&1; do
  sleep 1
done
echo "//> Ollama is ready."

# Check each model and pull if not present
for MODEL in "${MODELS[@]}"; do
  if ! ollama list | awk '{print $1}' | grep -qx "$MODEL"; then
    echo "//> Pulling $MODEL model..."
    ollama pull "$MODEL"
    echo "//> Model $MODEL pulled successfully."
  else
    echo "//> Model $MODEL already exists."
  fi
done

# Keep the container running by waiting on the Ollama process
wait
