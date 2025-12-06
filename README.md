# github-actions-docker-swarm-env

Deploy a Docker Swarm stack over SSH from GitHub Actions, with environment variable injection.

-   Secure SSH
-   Automatic key loading
-   Environment variable injection
-   Docker stack deploy

## Usage

```yaml
- uses: petrosyandev/github-actions-docker-swarm-env@v1
  with:
      ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
      ssh_host: ${{ secrets.SSH_HOST }}
      ssh_user: ${{ secrets.SSH_USER }}
      ssh_port: ${{ secrets.SSH_PORT }} # optional, default 22
      file: ./docker-compose.yml # path to compose/stack file
      stack_name: mystack
      env_list: | # optional, multi-line KEY=VALUE list
          POSTGRES_USER=myuser
          POSTGRES_PASSWORD=mypass
      registry: ghcr.io # optional, if using a private registry
      registry-username: ${{ secrets.REGISTRY_USER }} # optional
      registry-password: ${{ secrets.REGISTRY_PASSWORD }} # optional
      ssh_remote_known_hosts: ... # optional, known_hosts line
```

## Inputs

| Name                   | Required | Description                                                |
| ---------------------- | -------- | ---------------------------------------------------------- |
| ssh_private_key        | yes      | SSH private key for remote server                          |
| ssh_host               | yes      | Hostname or IP of Swarm manager node                       |
| ssh_user               | yes      | SSH username                                               |
| ssh_port               | no       | SSH port (default: 22)                                     |
| file                   | yes      | Path to stack or compose file on the server                |
| stack_name             | yes      | Name for the Docker stack                                  |
| env_list               | no       | Multi-line list (KEY=VALUE) of env vars for the deployment |
| registry               | no       | Container registry URL (for docker login)                  |
| registry-username      | no       | Registry username                                          |
| registry-password      | no       | Registry password or token                                 |
| ssh_remote_known_hosts | no       | SSH known_hosts line (recommended for secure connections)  |

## Notes

-   `env_list` lets you provide environment variables dynamically injected into the deployment environment.
-   If `ssh_remote_known_hosts` is omitted, `StrictHostKeyChecking=no` is used for SSH.
-   Private registry authentication is optional. Only set `registry`, `registry-username`, and `registry-password` if needed.

## Example

A minimal configuration:

```yaml
- uses: petrosyandev/github-actions-docker-swarm-env@v1
  with:
      ssh_private_key: ${{ secrets.SSH_KEY }}
      ssh_host: ${{ secrets.HOST }}
      ssh_user: ${{ secrets.USER }}
      file: ./docker-compose.yml
      stack_name: mystack
```

## License

MIT License.
