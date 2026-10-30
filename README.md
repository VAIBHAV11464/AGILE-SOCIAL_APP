# Agile Social App

A small social feed developed in three incremental releases for a DevOps course project. The interface uses a centered dark layout, plain text posts, and SQLite storage.

## Versions

| Git tag and branch | Features | Kubernetes service | Local URL |
| --- | --- | --- | --- |
| v1 | Create and read posts | social-app-v1 | http://localhost:30081 |
| v2 | Posts and one like per browser | social-app-v2 | http://localhost:30082 |
| v3 | Posts, likes and comments | social-app-v3 | http://localhost:30083 |

This is a classroom demonstration without user accounts. A display name identifies posts and comments. Browser identifiers prevent repeated likes in normal use; they are not user authentication.

## Run in VS Code

Open this folder in VS Code. Install Node.js 24 or newer, then run:

```powershell
npm.cmd ci
npm.cmd start
```

Open http://localhost:3000. Use the Run Social App launch configuration to debug. Data is stored in `data/social.db` and excluded from Git.

## Checks

```powershell
npm.cmd run check
npm.cmd test
```

The tests cover validation, persistence after restart, API version boundaries, and supported social interactions.

## Build and publish

Check out the required release tag before building its image:

```powershell
git checkout v1
docker build -t vaibhav11464/agile-social-app:v1 .
docker login --username vaibhav11464
docker push vaibhav11464/agile-social-app:v1
```

Use v2 or v3 for the other releases. Enter a Docker Hub personal access token when Docker asks for a password. Never put the token in source files or command arguments.

## Jenkins pipeline

The `agile-social-app` job loads `Jenkinsfile` from the main branch. Its VERSION parameter selects a release tag. The stages check out the release, run tests, build and test the Docker image, push to Docker Hub, deploy Kubernetes resources, and verify the running service.

This Windows installation uses Node.js in `C:\Program Files\nodejs`, Git in `D:\Git\cmd`, and the current user's Docker Desktop command-line tools. Adjust the Jenkinsfile PATH on another machine.

Configure two Jenkins credentials:

- `social-dockerhub`: username and token for Docker Hub.
- `social-kubeconfig`: secret file containing the Docker Desktop Kubernetes configuration.

Jenkins uses Docker Desktop's Linux engine through its named pipe. Its account needs permission to access that engine. No credentials belong in GitHub source. The push stage uses a temporary Docker configuration and removes it afterwards.

## Kubernetes

There is one deployment, NodePort service and persistent volume claim per version, in the `agile-social` namespace. Each database is separate. The pods run as an unprivileged user. Recreate deployment strategy avoids multiple writers during rollout.

```powershell
./scripts/deploy.ps1 -Version v1 -Image vaibhav11464/agile-social-app:v1
kubectl get deployments,services,pvc -n agile-social
./scripts/verify.ps1 -Version v1
```

On installations where NodePort is not forwarded to the Windows host, run `kubectl port-forward -n agile-social service/social-app-v1 30081:3000` in a terminal. Repeat for v2 and v3 on ports 30082 and 30083.

## Demonstration

1. Open each version at its localhost URL.
2. Create a post in v1.
3. Create a post and like or unlike it in v2.
4. Create a post, like it, and add a comment in v3.
5. Refresh the page to check persisted data.
6. Review the three successful Jenkins builds and Docker Hub tags.

The Word report and original screenshots are delivered separately from the application source.
