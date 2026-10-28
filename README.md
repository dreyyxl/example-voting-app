# Example Voting App

A simple distributed application running across multiple Docker containers.

## Getting started

Download [Docker Desktop](https://www.docker.com/products/docker-desktop) for Mac or Windows. [Docker Compose](https://docs.docker.com/compose) will be automatically installed. On Linux, make sure you have the latest version of [Compose](https://docs.docker.com/compose/install/).

This solution uses Python, Node.js, .NET, with Redis for messaging and Postgres for storage.

Run in this directory to build and run the app:

```shell
docker compose up
```

The `vote` app will be running at [http://localhost:8080](http://localhost:8080), and the `results` will be at [http://localhost:8081](http://localhost:8081).

Alternately, if you want to run it on a [Docker Swarm](https://docs.docker.com/engine/swarm/), first make sure you have a swarm. If you don't, run:

```shell
docker swarm init
```

Once you have your swarm, in this directory run:

```shell
docker stack deploy --compose-file docker-stack.yml vote
```

## Run the app in Kubernetes

The folder k8s-specifications contains the YAML specifications of the Voting App's services.

Run the following command to create the deployments and services. Note it will create these resources in your current namespace (`default` if you haven't changed it.)

```shell
kubectl create -f k8s-specifications/
```

The `vote` web app is then available on port 31000 on each host of the cluster, the `result` web app is available on port 31001.

To remove them, run:

```shell
kubectl delete -f k8s-specifications/
```

## Architecture

![Architecture diagram](architecture.excalidraw.png)

* A front-end web app in [Python](/vote) which lets you vote between two options
* A [Redis](https://hub.docker.com/_/redis/) which collects new votes
* A [.NET](/worker/) worker which consumes votes and stores them in…
* A [Postgres](https://hub.docker.com/_/postgres/) database backed by a Docker volume
* A [Node.js](/result) web app which shows the results of the voting in real time

## Notes

The voting application only accepts one vote per client browser. It does not register additional votes if a vote has already been submitted from a client.

This isn't an example of a properly architected perfectly designed distributed app... it's just a simple
example of the various types of pieces and languages you might see (queues, persistent data, etc), and how to
deal with them in Docker at a basic level.


---

# DevOps Capstone 1 — Voting Application

## Project Overview

This project demonstrates the containerization, automated testing, security scanning, CI/CD, infrastructure provisioning configuration, and Kubernetes deployment of a distributed voting application.

The application consists of five components: Vote (Python), Redis, Worker (.NET), PostgreSQL, and Result (Node.js).

## Architecture

```text
User → Vote → Redis → Worker → PostgreSQL
                                    ↓
                              Result → Browser
```

The architecture diagram is available in `architecture.excalidraw.png`.

## Docker and Testing

The five application services were containerized using Docker and tested locally with Docker Compose.

```bash
docker compose up --build -d
bash tests/integration-test.sh
docker compose down
```

The integration test verifies that submitting a vote increases the database vote count.

## CI/CD Pipeline

The GitHub Actions workflow at `.github/workflows/cicd.yml` automates:

1. Docker Compose integration testing.
2. Trivy scanning for CRITICAL vulnerabilities in the Vote, Result, and Worker images.
3. Building and publishing three application images to GitHub Container Registry (GHCR), tagged with the Git commit SHA.

Successful CI/CD execution:

https://github.com/dreyyxl/example-voting-app/actions/runs/40646876102

## Infrastructure as Code

The `terraform/` directory contains Terraform configuration for AWS EKS infrastructure.

Terraform validation passed successfully. However, the AWS infrastructure was not provisioned, and destroy/recreate operations were not performed because of cloud costs.

Instead, Kubernetes deployment was demonstrated using a local Kind cluster.

## Kubernetes Deployment with Helm

The Helm chart is located in `voting-app-helm/`.

A local Kubernetes cluster was created using:

```bash
kind create cluster --name voting-cluster
```

A Kubernetes Secret named `voting-db-credentials` was created for the PostgreSQL password.

The application was deployed using:

```bash
helm install voting-app ./voting-app-helm \
  --set global.imageTag=e80149f31fa969ad88dca1a4da749f0c7ce93ae1
```

All five application Pods reached `1/1 Running`.

The Vote and Result interfaces were tested using Kubernetes port forwarding:

```bash
kubectl port-forward svc/vote 5000:5000
kubectl port-forward svc/result 5001:5001
```

The interfaces were accessible at `http://localhost:5000` and `http://localhost:5001`, respectively. Each port-forward command was run in a separate terminal.

## Helm Rollback Demonstration

A deliberately invalid Vote image was introduced using:

```bash
helm upgrade voting-app ./voting-app-helm \
  --reuse-values \
  --set vote.image=ghcr.io/dreyyxl/nonexistent-vote-image
```

The new Vote Pod entered `ImagePullBackOff`.

The previous working release was restored using:

```bash
helm rollback voting-app 1
```

Verification confirmed all five Pods were running successfully.

Helm history recorded:

- Revision 1 — Original installation
- Revision 2 — Faulty image upgrade
- Revision 3 — Successful rollback to revision 1

## Results and Limitations

The Docker integration test, GitHub Actions pipeline, Trivy CRITICAL vulnerability checks, Helm chart validation, Kubernetes deployment, and Helm rollback demonstration completed successfully.

The Kubernetes deployment was tested locally using Kind rather than AWS EKS. PostgreSQL uses ephemeral storage in this demonstration, so the database is not configured for production-grade persistence.