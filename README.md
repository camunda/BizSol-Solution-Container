# Camunda Process Application Container

This container serves as a Docker Compose-based transport means for Camunda Business Solutions.  
The latter consist of predefinded, production-ready Building Blocks that are also Camunda applications.

![alt text](<_assets/Process Application Container.png>)

The Camunda Process Application Container serves well for Demo, Development and QA purposes but should not be taken into Production as-is - because your specific infrastructure requirements might not be fully reflected here.

## Configuration

This host/port and all other hostnames and ports can be configured in a `.env`, see `.env.example` as a template.  
Also, all Building Blocks are expected to bring their own `.env`, which will automatically be merged into the overall scope by Docker Compose.


## Base Services

### Cosmos DB



### camunda-check
An optional on-demand `camunda-check` service can check for a running Camunda instance on (per default) `localhost:8080`.
An LLM server must be running and reachable on `localhost:11434`.

Sample startup commands:

```bash
# Default startup (no optional profile services)
docker compose up -d

# Run Camunda availability check on demand
docker compose --profile checks up camunda-check

# Start optional local LLM stack (ollama + Open WebUI)
docker compose --profile ollama up -d

# Start everything including optional checks and LLM stack
docker compose --profile checks --profile ollama up -d
```

Sample stop commands:

```bash
# Stop and remove all running services from this compose project
docker compose down

# Stop optional local LLM stack services explicitly
docker compose stop ollama open-webui

# Stop Camunda check container if started on demand
docker compose stop camunda-check
```


- **ollama + Open WebUI** (optional, on-demand)

### `ollama`

`ollama:11434`

The dockerized `ollama` service is optional and does not start by default. Start it on demand if you want a local bundled LLM server. It serves on `localhost:11434`; `open-webui` is in the same profile and starts together with `ollama`.

### Open WebUI

`http://localhost:3000`


## Port Mappings and FS Exports

### Port Mappings

| File | Service | Host Port | Container Port | Purpose |
|---|---|---|---|---|
| `docker-compose.ai.yaml` | `ollama` | `${OLLAMA_PORT:-11434}` | 11434 | Ollama LLM API |
| `docker-compose.ai.yaml` | `open-webui` | `${WEBUI_PORT:-3000}` | 8080 | Open WebUI |
| `docker-compose.vector-db.yml` | `cosmosdb` | `${COSMOSDB_API_PORT:-8181}` | 8081 | NoSQL API endpoint (HTTP) |
| `docker-compose.vector-db.yml` | `cosmosdb` | `${COSMOSDB_HEALTH_PORT:-8180}` | 8080 | Health/readiness probes |
| `docker-compose.vector-db.yml` | `cosmosdb` | `${COSMOSDB_EXPLORER_PORT:-1234}` | 1234 | Data Explorer UI |

`docker-compose.yml` (`camunda-check`) and `BizSol_bb-sample/docker-compose.yaml` (`sample-java-worker`, `sample-node-worker`) expose no ports.

### Filesystem Mappings

| File | Service | Host Path | Container Path | Type |
|---|---|---|---|---|
| `docker-compose.ai.yaml` | `ollama` | `./container-maps/ollama` | `/root/.ollama` | Bind mount (model data) |
| `docker-compose.ai.yaml` | `ollama` | `./container-maps/ollama-entrypoint.sh` | `/ollama-entrypoint.sh` | Bind mount (entrypoint script) |
| `docker-compose.ai.yaml` | `open-webui` | `./container-maps/open-webui` | `/app/backend/data` | Bind mount (WebUI data) |
| `docker-compose.vector-db.yml` | `cosmosdb` | `./container-maps/cosmosdb-data` | `/tmp/cosmos/appdata` | Bind mount (persistence) |
| `BizSol_bb-sample/docker-compose.yaml` | `sample-java-worker` | `./java` | `/app` | Bind mount (source code) |
| `BizSol_bb-sample/docker-compose.yaml` | `sample-java-worker` | `sample-maven-cache` | `/root/.m2` | Named volume (Maven cache) |
| `BizSol_bb-sample/docker-compose.yaml` | `sample-node-worker` | `./nodejs` | `/app` | Bind mount (source code) |
| `BizSol_bb-sample/docker-compose.yaml` | `sample-node-worker` | `sample-node-modules` | `/app/node_modules` | Named volume (node_modules cache) |

## Building Blocks

Building Blocks (any dir name containing `*_bb-*`) are considered ready to run artifacts that can be reused here as part of a "Business Solution". A sample is included as `BizSol_bb-sample`, showcasing the idea; the reuse of BPMN artifacts from `BizSol_bb-sample` happens in `my-solution/my-process.bpmn`.

## Development Accelerator

In conjunction with `c8run` and `c8ctl`, this setup is intended to enable "flight-mode" development, with no external network dependencies. This isolated environment in turn provides the fastest possible feedback loop for developing Camunda-based solutions.

![alt text](_assets/inner-loop.png)

`c8run`: https://downloads.camunda.cloud/release/camunda/c8run/  
`c8ctl`: https://www.npmjs.com/package/@camunda8/cli
