# BizSol_bb-sample

Sample workers for Camunda 8, sourced from the [camunda-8-get-started](https://github.com/camunda/camunda-8-get-started) repository.

## Contents

- **java/** - Java worker example using Spring Boot
- **nodejs/** - Node.js worker example using TypeScript

## Sparse Checkout Commands

To fetch only specific subdirectories from the upstream repository:

### Java Worker

```bash
git clone --filter=blob:none --no-checkout --depth 1 --sparse \
  https://github.com/camunda/camunda-8-get-started.git java && \
  cd java && git sparse-checkout set java && git checkout && rm -rf .git
```

### Node.js Worker

```bash
git clone --filter=blob:none --no-checkout --depth 1 --sparse \
  https://github.com/camunda/camunda-8-get-started.git nodejs && \
  cd nodejs && git sparse-checkout set nodejs && git checkout && rm -rf .git
```

## Command Explanation

| Flag / Step | Purpose |
|-------------|---------|
| `--filter=blob:none` | Download only tree objects, fetch file contents on demand |
| `--no-checkout` | Don't checkout files after cloning |
| `--depth 1` | Shallow clone with only the latest commit |
| `--sparse` | Enable sparse-checkout mode |
| `rm -rf .git` | Remove git metadata to avoid submodule conflicts |

This approach minimizes download size and places files directly in the target directory matching the upstream folder name.
