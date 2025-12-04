# GitHub Actions Docker Swarm Environment

A GitHub Action that deploys Docker Swarm stacks over SSH with environment variable injection.

## What This Action Does

This action connects to a remote Docker Swarm manager via SSH and deploys a Docker stack using a compose file. It supports:

-   **SSH-based deployment**: Securely connects to your Docker Swarm manager using ssh-agent
-   **Environment variable injection**: Pass environment variables to your stack deployment
-   **Registry authentication**: Uses `--with-registry-auth` flag for private registry access
-   **Flexible configuration**: Customizable SSH port, remote working directory, and stack file paths
-   **Secure SSH handling**: Supports known_hosts verification for enhanced security
-   **Automatic workdir**: Automatically uses `/home/<ssh_user>/<repository>` as the remote working directory

## Inputs

| Input                    | Description                                                                                             | Required | Default                                |
| ------------------------ | ------------------------------------------------------------------------------------------------------- | -------- | -------------------------------------- |
| `ssh_private_key`        | SSH private key for authentication                                                                      | ✅ Yes   | -                                      |
| `ssh_host`               | Hostname or IP address of the Swarm manager                                                             | ✅ Yes   | -                                      |
| `ssh_user`               | SSH username                                                                                            | ✅ Yes   | `root`                                 |
| `ssh_remote_port`        | SSH port of the remote server                                                                           | ❌ No    | `22`                                   |
| `file`                   | Path to the stack/compose file (relative to `remote_workdir` on the remote server)                      | ✅ Yes   | -                                      |
| `stack_name`             | Name of the Docker Swarm stack                                                                          | ✅ Yes   | -                                      |
| `env_list`               | Multi-line KEY=VALUE list of environment variables to export before running docker stack                | ❌ No    | `""`                                   |
| `ssh_remote_known_hosts` | Optional known_hosts line for your SSH server (host key). If omitted, ssh-keyscan is used (less secure) | ❌ No    | -                                      |
| `remote_workdir`         | Optional remote working directory. Defaults to `/home/<ssh_user>/<GITHUB_REPOSITORY>`                   | ❌ No    | `/home/<ssh_user>/<GITHUB_REPOSITORY>` |

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
                  file: "docker/run.yml"
                  stack_name: "my-app"
```

**Note:** The `file` path is relative to the remote working directory (defaults to `/home/<ssh_user>/<repository>`). For example, if your repository is `owner/my-repo` and the compose file is at `docker/run.yml` in the repo, the action will look for it at `/home/<ssh_user>/owner/my-repo/docker/run.yml` on the remote server.

### With Environment Variables and Custom Configuration

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
                  file: "docker/run.yml"
                  stack_name: ${{ env.PROJECT_NAME }}
                  remote_workdir: "/opt/my-app"
                  env_list: |
                      DB_NAME=${{ secrets.DB_NAME }}
                      DB_PASSWORD=${{ secrets.DB_PASSWORD }}
                      API_KEY=${{ secrets.API_KEY }}
```

### With Known Hosts (Recommended for Security)

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
                  ssh_remote_known_hosts: ${{ secrets.SSH_KNOWN_HOSTS }}
                  file: "docker/run.yml"
                  stack_name: "my-app"
                  env_list: |
                      DB_NAME=${{ secrets.DB_NAME }}
                      DB_PASSWORD=${{ secrets.DB_PASSWORD }}
```

**Security Note:** Providing `ssh_remote_known_hosts` enables strict host key checking. To get the known_hosts line, run `ssh-keyscan -p <port> <host>` on your local machine and add it as a secret.

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
                  file: "docker/run.yml"
                  stack_name: "production-stack"
                  env_list: |
                      IMAGE_TAG=${{ github.sha }}
                      ENVIRONMENT=production
                      DB_CONNECTION_STRING=${{ secrets.DB_CONNECTION_STRING }}
```

## How It Works

1. The action sets up SSH authentication using ssh-agent with the provided private key
2. It configures known_hosts verification (either from `ssh_remote_known_hosts` or via ssh-keyscan)
3. It connects to the remote Docker Swarm manager via SSH
4. It changes to the remote working directory (defaults to `/home/<ssh_user>/<GITHUB_REPOSITORY>`)
5. Environment variables from `env_list` are exported on the remote host
6. The Docker stack is deployed using `docker stack deploy --with-registry-auth` with the compose file (relative to the remote workdir)
7. The stack name is used as specified

## Notes

-   The `file` path is **relative** to the `remote_workdir` on the remote server (not an absolute path)
-   The default `remote_workdir` is `/home/<ssh_user>/<GITHUB_REPOSITORY>` (e.g., `/home/erik/owner/my-repo`)
-   The `env_list` should be in the format `KEY=VALUE`, one per line
-   Empty lines and lines starting with `#` are ignored in `env_list`
-   Values are automatically quoted to handle special characters
-   The action uses `--with-registry-auth` flag to support private Docker registries
-   SSH key handling supports both Unix and Windows line endings
-   For better security, provide `ssh_remote_known_hosts` to enable strict host key checking
-   Make sure your SSH key has access to the remote server and Docker commands
-   The action uses ssh-agent for secure key handling (no key files written to disk)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
