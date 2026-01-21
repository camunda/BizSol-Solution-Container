# BizSol

Docker Compose setup for a "Process Application" that contains

- Building Blocks
  - BPMNs
  - DMNs
  - job worker
- Infrastructure
  - Ollama (for local LLM usage)
  - Open WebUI (for convience chats with local LLMs)

## Services

### Building Blocks
- **JSON Converter** (`BizSol_bb-prompt-safeguard`) - Camunda Job Worker that converts JSON strings to JSON objects (job type: `json-converter`)

### Infrastructure

- **Ollama** - Local LLM inference server
- **Open WebUI** - Web interface for interacting with Ollama models

## Quick Start

```bash
docker compose up -d
```

Open WebUI will be available at <http://localhost:3000>

## Configuration

Ports are configured in `.env`:

```env
OLLAMA_PORT=11434
WEBUI_PORT=3000
```

Override at runtime: `WEBUI_PORT=8080 docker compose up -d`

## Prerequisites

### Docker Desktop Memory Requirements

Running LLMs locally requires significant RAM. **Recommended: at least 16 GB** allocated to Docker.

To configure Docker Desktop memory:

1. Open **Docker Desktop**
2. Go to **Settings** (gear icon)
3. Select **Resources** → **Advanced**
4. Adjust the **Memory** slider to at least **16 GB**
5. Click **Apply & Restart**

| Model Size | Minimum RAM Required |
| ---------- | -------------------- |
| 1-3B       | 4 GB                 |
| 7B         | 8 GB                 |
| 13B        | 16 GB                |
| 30B+       | 32 GB+               |

> ⚠️ If you see errors like `model requires more system memory than is available`, increase Docker's memory allocation or use a smaller model variant.

## Ollama Entrypoint Script

The `ollama-entrypoint.sh` script automatically:

1. Starts the Ollama server
2. Detects system resources (CPU/RAM) to optimize startup timing
3. Ensures the specified models in `ollama-entrypoint.sh` model are downloaded

### Platform Support

The script detects CPU cores and RAM across multiple platforms:

| Platform                      | CPU Detection                   | RAM Detection        |
| ----------------------------- | ------------------------------- | -------------------- |
| **Linux**                     | `nproc` or `/proc/cpuinfo`      | `/proc/meminfo`      |
| **Windows/WSL**               | `$NUMBER_OF_PROCESSORS` env var | `/proc/meminfo`      |
| **Windows (Git Bash/MSYS2)**  | `wmic` command                  | `wmic` command       |
| **macOS**                     | `sysctl hw.ncpu`                | `sysctl hw.memsize`  |

If detection fails, safe defaults are used (2 cores, 4GB RAM).

### Hardware-Based Sleep Tuning

The initial sleep before checking Ollama readiness is calculated based on a hardware score:

- **Score formula**: `(CPU cores × 2) + RAM (GB)`
- **Score ≥ 32** (e.g., 8 cores + 16GB): 3 second sleep
- **Score ≥ 16** (e.g., 4 cores + 8GB): 6 seconds sleep
- **Score < 16**: 9 seconds sleep

## Pulling Additional Models

```bash
docker exec ollama ollama pull <model-name>
```

Example:

```bash
docker exec ollama ollama pull llama3.2
```

## Building Blocks (Camunda Job Workers)

This project includes reusable Camunda Job Workers as "building blocks" for AI-powered process automation.

### JSON Converter (`BizSol_bb-prompt-safeguard/JsonConverter`)

A Spring Boot Job Worker that converts JSON strings to JSON objects.

| Property | Value |
| -------- | ----- |
| **Job Type** | `json-converter` |
| **Input Variable** | `jsonString` - A stringified JSON object |
| **Output Variable** | `result` - The parsed JSON object |

**Run with Docker Compose:**

```bash
docker compose -f docker-compose.bb.yaml up BizSol_bb-prompt-safeguard -d
```

**Run standalone:**

```bash
cd BizSol_bb-prompt-safeguard/JsonConverter
mvn spring-boot:run
```

For more details, see [BizSol_bb-prompt-safeguard/JsonConverter/README.md](BizSol_bb-prompt-safeguard/JsonConverter/README.md).

### Sample BPMN Processes

| Building Block | Sample Processes |
| -------------- | ---------------- |
| Token Monitor | `BizSol_bb-Token-Monitor/inference-monitor-samples.bpmn`, `BizSol_bb-Token-Monitor/min-ollama-sample.bpmn` |
| Prompt Safeguard | `BizSol_bb-prompt-safeguard/safeguard-agent.orig.bpmn` |
