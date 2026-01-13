#!/bin/bash

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

# Check if llama-guard3:1b model exists, if not pull it
if ! ollama list | grep -q "llama-guard3:1b"; then
  echo "//> Pulling llama-guard3:1b model..."
  ollama pull llama-guard3:1b
  echo "//> Model llama-guard3:1b pulled successfully."
else
  echo "//> Model llama-guard3:1b already exists."
fi

# Keep the container running by waiting on the Ollama process
wait
