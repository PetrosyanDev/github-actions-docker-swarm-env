## About

GitHub Actions + Docker Swarm (with envs)

## Usage

Example

```yml
name: Production
on:
    push:
        branches:
            - main

jobs:
    deploy:
        needs: build
        runs-on: ubuntu-24.04
        steps:
            - uses: petrosyandev/github-actions-docker-swarm-env@v1
              with:
                  ssh_private_key: "${{ secrets.SSH_DEPLOY_PRIVATE_KEY }}"
                  ssh_host: "${{ secrets.SSH_HOST }}"
                  ssh_user: "${{ secrets.SSH_USER }}"
                  file: "/docker/run.yml"
                  registry: "ghcr.io"
                  registry-username: "${{ github.actor }}"
                  registry-password: "${{ secrets.GITHUB_TOKEN }}"
                  stack_name: "${{ env.PROJECT_NAME }}"
                  env_list: |
                      DB_NAME=${{ secrets.DB_NAME }}
```
