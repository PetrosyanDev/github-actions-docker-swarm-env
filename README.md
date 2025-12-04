# GitHub Actions Docker Swarm Environment

A GitHub Action that deploys Docker Swarm stacks over SSH with environment variable injection.

## What This Action Does

This action connects to a remote Docker Swarm manager via SSH and deploys a Docker stack using a compose file. It supports:

-   **SSH-based deployment**: Securely connects to your Docker Swarm manager
-   **Environment variable injection**: Pass environment variables to your stack deployment
-   **Registry authentication**: Uses `--with-registry-auth` flag for private registry access
-   **Flexible configuration**: Customizable SSH port and stack file paths

## Inputs

| Input             | Description                                                             | Required | Default |
| ----------------- | ----------------------------------------------------------------------- | -------- | ------- |
| `ssh_private_key` | SSH private key for authentication                                      | ✅ Yes   | -       |
| `ssh_host`        | Hostname or IP address of the Swarm manager                             | ✅ Yes   | -       |
| `ssh_user`        | SSH username                                                            | ✅ Yes   | -       |
| `ssh_remote_port` | SSH port of the remote server                                           | ❌ No    | `22`    |
| `file`            | Path to the stack/compose file on the remote server                     | ✅ Yes   | -       |
| `stack_name`      | Name of the Docker Swarm stack                                          | ✅ Yes   | -       |
| `env_list`        | Multiline list of environment variables to export (format: `KEY=VALUE`) | ❌ No    | `""`    |

## Example Usage

### Basic Example

```yaml
name: Deploy to Production
on:
    push:
        branches:
            - main

jobs:
    deploy:
        runs-on: ubuntu-latest
        steps:
            - name: Deploy Docker Swarm Stack
              uses: petrosyandev/github-actions-docker-swarm-env@v1
              with:
                  ssh_private_key: ${{ secrets.SSH_DEPLOY_PRIVATE_KEY }}
                  ssh_host: ${{ secrets.SSH_HOST }}
                  ssh_user: ${{ secrets.SSH_USER }}
                  file: "/docker/run.yml"
                  stack_name: "my-app"
```

### With Environment Variables

```yaml
name: Deploy to Production
on:
    push:
        branches:
            - main

jobs:
    deploy:
        runs-on: ubuntu-latest
        steps:
            - name: Deploy Docker Swarm Stack
              uses: petrosyandev/github-actions-docker-swarm-env@v1
              with:
                  ssh_private_key: ${{ secrets.SSH_DEPLOY_PRIVATE_KEY }}
                  ssh_host: ${{ secrets.SSH_HOST }}
                  ssh_user: ${{ secrets.SSH_USER }}
                  ssh_remote_port: "2222"
                  file: "/docker/run.yml"
                  stack_name: ${{ env.PROJECT_NAME }}
                  env_list: |
                      DB_NAME=${{ secrets.DB_NAME }}
                      DB_PASSWORD=${{ secrets.DB_PASSWORD }}
                      API_KEY=${{ secrets.API_KEY }}
```

### Complete Workflow Example

```yaml
name: CI/CD Pipeline
on:
    push:
        branches:
            - main

jobs:
    build:
        runs-on: ubuntu-latest
        steps:
            - name: Build and push Docker image
              run: |
                  docker build -t ghcr.io/${{ github.repository }}:${{ github.sha }} .
                  docker push ghcr.io/${{ github.repository }}:${{ github.sha }}

    deploy:
        needs: build
        runs-on: ubuntu-latest
        steps:
            - name: Deploy to Docker Swarm
              uses: petrosyandev/github-actions-docker-swarm-env@v1
              with:
                  ssh_private_key: ${{ secrets.SSH_DEPLOY_PRIVATE_KEY }}
                  ssh_host: ${{ secrets.SSH_HOST }}
                  ssh_user: ${{ secrets.SSH_USER }}
                  file: "/docker/run.yml"
                  stack_name: "production-stack"
                  env_list: |
                      IMAGE_TAG=${{ github.sha }}
                      ENVIRONMENT=production
                      DB_CONNECTION_STRING=${{ secrets.DB_CONNECTION_STRING }}
```

## How It Works

1. The action sets up SSH authentication using the provided private key
2. It connects to the remote Docker Swarm manager via SSH
3. Environment variables from `env_list` are exported on the remote host
4. The Docker stack is deployed using `docker stack deploy --with-registry-auth`
5. The stack file path and stack name are used as specified

## Notes

-   The `env_list` should be in the format `KEY=VALUE`, one per line
-   Empty lines and lines starting with `#` are ignored
-   Values are automatically quoted to handle special characters
-   The action uses `--with-registry-auth` flag to support private Docker registries
-   Make sure your SSH key has access to the remote server and Docker commands

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
