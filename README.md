# Camunda Process Application Container

This container serves as a Docker Compose-based transport means for Camunda Business Solutions.  
The latter consist of predefinded, production-ready Building Blocks that are also Camunda applications.

![alt text](<_assets/Process Application Container.png>)

The Camunda Process Application Container serves well for Demo, Development and QA purposes but should not be taken into Production as-is - because your specific infrastructure requirements might not be fully reflected here.

## Configuration

This host/port and all other hostnames and ports can be configured in a `.env`, see `.env.example` as a template.  
Also, all Building Blocks are expected to bring their own `.env`, which will automatically be merged into the overall scope by Docker Compose.


## Base Services

The overall startup of the Container checks for a running Camunda instance on (per default) `localhost:8080`. 


- **ollama** for local LLMs
- **Open WebUI** for freestyle chat interface

### `ollama`

`ollama:11434`

The services checks at start-time whether a local, native `ollama` instance is running. If so, it will be reused in the overall setup. If not, the dockerized `ollama` is started and used. For the latter, the "gpt-oss" model is pulled per default. You can customize this by changing `DEFAULT_MODELS` in `ollama-entrypoint.sh`.

### Open WebUI

`http://localhost:3000`


## Building Blocks

Building Blocks (any dir name containing `*_bb-*`) are considered ready to run artifacts that can be reused here as part of a "Business Solution". A sample is included as `BizSol_bb-sample`, showcasing the idea; the reuse of BPMN artifacts from `BizSol_bb-sample` happens in `my-solution/my-process.bpmn`.

## Development Accelerator

In conjunction with `c8run` and `c8ctl`, this setup is intended to enable "flight-mode" development, with no external network dependencies. This isolated environment in turn provides the fastest possible feedback loop for developing Camunda-based solutions.

![alt text](_assets/inner-loop.png)

`c8run`: https://downloads.camunda.cloud/release/camunda/c8run/  
`c8ctl`: https://www.npmjs.com/package/@camunda8/cli
