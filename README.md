# README

- [README](#readme)
- [Step 1: Develop the R Workflow](#step-1-develop-the-r-workflow)
- [Step 2: Define Dependencies](#step-2-define-dependencies)
- [Step 3: Create the Python Runner](#step-3-create-the-python-runner)
- [Step 4: Local Validation and Testing](#step-4-local-validation-and-testing)
- [Step 5: Create the pyproject.toml file](#step-5-create-the-pyprojecttoml-file)
- [Step 6: # Building and Pushing to ECR](#step-6--building-and-pushing-to-ecr)
  - [What is this?](#what-is-this)
  - [Prerequisites](#prerequisites)
  - [0. Build the base images (first time only)](#0-build-the-base-images-first-time-only)
  - [1. Set your variables](#1-set-your-variables)
  - [2. Create the ECR repository *( first time only)](#2-create-the-ecr-repository--first-time-only)*
  - [3. Build the image](#3-build-the-image)
  - [4. Authenticate Docker with ECR](#4-authenticate-docker-with-ecr)
  - [5. Tag the image for ECR](#5-tag-the-image-for-ecr)
  - [6. Push to ECR](#6-push-to-ecr)
  - [Notes](#notes)
- [Installation on the platform (handled by Mass Dynamics)](#installation-on-the-platform-handled-by-mass-dynamics)

This repository provides instructions and an example for setting up a
new custom R workflow integrated into the Mass Dynamics ecosystem.

The example in this repository demonstrates how to create a workflow
that modifies an input intensity dataset and returns a new transformed
intensity dataset.

# Step 1: Develop the R Workflow

Create an R workflow as either a package or a standalone function. Include:

- a main function that executes the workflow.
- an optional runner script in a separate file (e.g.`process.R`) - required for R packages.

Structure it as follows:

- If using an R package: the runner script loads the package and calls the main workflow function. See an example runner here:
[https://github.com/MassDynamics/MDCustomR/blob/updates-wip/src/md_custom_r/process.R](https://github.com/MassDynamics/MDCustomR/blob/updates-wip/src/md_custom_r/process.R)
- If using a script: the runner can be the same as the main workflow function, so no separate file is required.

If building an R package, include a `DESCRIPTION` with version constraints for dependencies.

The example in this repository is implemented as an R package, with the workflow located at `./R/transformIntensities.R`. This package depends on the `limma` and `tidyr` R packages.

**When to use an R package vs an R script**

Use an R package when your workflow has many functions, you want versioning and explicit dependency management, need dev tools (testing, CI/CD), or plan to release it for others to install from GitHub.

Use an R script when the workflow is simple (few functions, one main runner), you're iterating quickly, or you don't need package tooling.

The main R function should accept an intensity table and a metadata
table as inputs. Additional parameters of your choice can also be
included. The input and output tables must adhere to the standard Mass
Dynamics format for your chosen dataset type.

Develop an optional runner function to invoke the main workflow function and
produce the output as a named list. An example of this function is
provided in `./src/md_custom_r/process.R`.

**Output dataset types**

Your workflow can produce any of these dataset types and the outputs need to be dataframes. The R output list structure must match the type.

- **INTENSITY** — Required: `intensity`, `metadata`. Optional: `runtime_metadata`, `ptm_sites`
- **PAIRWISE** — Required: `results`. Optional: `runtime_metadata`
- **ANOVA** — Required: `results`. Optional: `runtime_metadata`
- **ENRICHMENT** — Required: `results`. Optional: `runtime_metadata`, `database_metadata`
- **DOSE_RESPONSE** — Required: `output_curves`, `output_volcanoes`, `input_drc`. Optional: `runtime_metadata`

See [md_dataset models](https://github.com/MassDynamics/md_dataset/blob/main/src/md_dataset/models/dataset.py) for full details.

# Step 2: Define Dependencies

Create `dependencies.R` to list all R packages — this file is required and runs during the Docker build. For step-by-step instructions on creating `DESCRIPTION` and `dependencies.R` (whether you're starting from scratch or have an existing package), see the [tutorial](tutorial/setup-r-package.Rmd). 

**R packages**

- `dependencies.R` — installs R packages *before* the R package or script. Use for base CRAN/Bioconductor packages (e.g. `BiocManager::install("limma")`) and packages not listed in `DESCRIPTION` (if using an R package)
- **R package only:** define version constraints in `DESCRIPTION` (e.g. `limma (>= 3.42.2)`)
- **R package only:** create `install.R` (e.g. `devtools::install()`) to install your package

**System dependencies**

- `dependencies.sh` — optional; installs system libraries (e.g. harfbuzz, libxml2). Often discovered when the Docker build fails during R package install.

# Step 3: Create the Python Runner

Create a Python runner (`process_r.py`), as shown in `./src/md_custom_r/process_r.py`. This file defines the form that surfaces parameters to users in the MD platform. This script uses
the Mass Dynamics `md_dataset` Python package to prepare the R input and
execute the workflow in Prefect.

The Python runner performs three things:

1. **Define parameters** — which arguments to expose to the user
2. **Configure the form** — how they appear in the UI (follow [md_form guidelines](https://github.com/MassDynamics/md_form))
3. **Pass parameters** — map form values to the R runner via `RFuncArgs`

Any parameter the user must specify must be defined in the form. Use the `@md_r` decorator with the `r_file` path and `r_function` from Step 1. In this file you prepare the dataframes and program arguments passed to the R runner.

# Step 4: Local Validation and Testing

Before deploying, validate the workflow:

1. **Test the R workflow** — run the main function with representative data
2. **Test via Python runner** — invoke the Python entrypoint (e.g. from a Jupyter notebook) to exercise the full flow
3. **Test via Docker** — build and run the Docker image to mimic the deployment environment

A Jupyter notebook or script that invokes the Python runner with sample data helps validate end-to-end behaviour before submission. See [tutorial/test-process-r.ipynb](tutorial/test-process-r.ipynb) for an example using in-memory data (no AWS or MD platform required).

**NOTE:** When DataFrames are passed through rpy2, small representation differences (often around the 10th decimal) can occur. These are far smaller than any biological difference, but they could affect downstream analysis at times. When writing tests, use tolerance‑based comparisons (`np.allclose`, `pandas.testing.assert_frame_equal` with `check_exact=False`, `rtol`/`atol`) instead of exact equality (`==`). 

# Step 5: Create the pyproject.toml file

Create `pyproject.toml` — this file is required. It provides details about the package, including its versions, dependencies, and authors. For reference, see the example `pyproject.toml` in this repository.

**Why is there a Python package with the R code?** The Mass Dynamics platform runs Python. The Python package wraps the R workflow via `md_dataset` and the `@md_r` decorator — it is required for integration.

In `pyproject.toml`, specify:

- This package's version
- The latest `md_dataset` version (unless a specific version is explicitly needed)

# Step 6: Building and Pushing to ECR

## What is this?

This workflow packages a custom R script into a **Docker image** — a self-contained bundle that includes R, all dependencies, and the package itself — and pushes it to **ECR (Elastic Container Registry)**, which is AWS's private Docker image registry. From there, the MD platform can pull and run the image in Kubernetes.

Think of it like: *build a reproducible computational environment → ship it to AWS → the platform runs it on demand*.

---

## Prerequisites

- **AWS CLI** installed and configured (`aws configure`) — [install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Docker Desktop** installed and running — [download for Mac](https://www.docker.com/products/docker-desktop/). After installing, make sure Docker Desktop is open before running any `docker` commands.
- The following AWS IAM permissions on your profile:
  - `ecr:GetAuthorizationToken`
  - `ecr:CreateRepository`
  - `ecr:BatchCheckLayerAvailability`
  - `ecr:PutImage`
  - `ecr:InitiateLayerUpload`
  - `ecr:UploadLayerPart`
  - `ecr:CompleteLayerUpload`

---

## 0. Build the base images *(first time only)*

Our image is built on top of a base image from the `[md_dataset](https://github.com/MassDynamics/md_dataset)` repo (clone or fork it first) that provides Python + R in an Amazon Linux environment. You need to build this locally first.

```bash
cd /path/to/your-fork-of-md_dataset

# Step 1 — build the Python+R base
docker build -t md_dataset_package-linux-base:latest -f base.Dockerfile --platform="linux/amd64" .

# Step 2 — build the R base (this is what custom R scripts use)
docker build \
  --build-arg BASE_IMAGE=md_dataset_package-linux-base:latest \
  -t md_dataset_package-linux-r-base:latest \
  -f r.base.Dockerfile \
  --platform="linux/amd64" .
```

> These builds take a while — they compile R and install system libraries. You only need to redo this if the `md_dataset` base image changes.

---

## 1. Set your variables

```bash
export AWS_PROFILE=eb-services-cli
export AWS_REGION=ap-southeast-2
export IMAGE_NAME=<your-repo-name>   # e.g. md_impute_knn_tn
export IMAGE_TAG=<version>-1         # e.g. 0.1.8-1; bump the suffix on each new push

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile $AWS_PROFILE)
export REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

> `IMAGE_TAG` follows the pattern `<version>-<build_number>`. The version comes from `pyproject.toml`. Increment the build number each time you push a new image for the same version.
> Each terminal session has its own environment — if you open a new terminal, re-run these exports before continuing.

---

## 2. Create the ECR repository *(first time only)*

ECR is where AWS stores your Docker images. This creates a private repository for this workflow.

```bash
aws ecr create-repository \
  --repository-name $IMAGE_NAME \
  --region $AWS_REGION \
  --image-tag-mutability IMMUTABLE \
  --encryption-configuration encryptionType=AES256 \
  --profile $AWS_PROFILE
```

> `IMMUTABLE` means once a tag (e.g. `0.1.8-1`) is pushed it cannot be overwritten — this is intentional and good practice for reproducibility. If you need to push a fix, bump the build number (e.g. `0.1.8-2`).
> The repository will be **private by default**. You can confirm this in the AWS Console under ECR → Repositories.
> If the repository already exists this command returns an error you can safely ignore, or check first with:

```bash
aws ecr describe-repositories --repository-names $IMAGE_NAME --profile $AWS_PROFILE
```

---

## 3. Build the image

This builds the Docker image for your custom R workflow on top of the R base image built in step 0.

```bash
cd /path/to/your-custom-r-repo

docker build \
  --build-arg BASE_IMAGE=md_dataset_package-linux-r-base:latest \
  -t $IMAGE_NAME:$IMAGE_TAG \
  -f Dockerfile \
  --platform="linux/amd64" \
  .
```

> `--platform="linux/amd64"` is required even on Apple Silicon Macs — the image must target the Linux/amd64 architecture that runs in the cloud.

---

## 4. Authenticate Docker with ECR

Docker needs a temporary token to push to the private registry. This command fetches one from AWS and logs Docker in automatically.

```bash
aws ecr get-login-password --region $AWS_REGION --profile $AWS_PROFILE \
  | docker login --username AWS --password-stdin ${REGISTRY}
```

---

## 5. Tag the image for ECR

ECR requires the image name to carry the full registry URI as a prefix before it can be pushed.

```bash
docker tag $IMAGE_NAME:$IMAGE_TAG ${REGISTRY}/$IMAGE_NAME:$IMAGE_TAG
```

---

## 6. Push to ECR

```bash
docker push ${REGISTRY}/$IMAGE_NAME:$IMAGE_TAG
```

The full image URI (needed for the deploy step) will be:

```text
<AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/<IMAGE_NAME>:<IMAGE_TAG>
```

---

## Notes

- **Do not push a `latest` tag** — the repo is `IMMUTABLE`, so `latest` would be locked to one digest and cannot be updated. Always use versioned tags only.
- To delete an accidentally pushed tag: `aws ecr batch-delete-image --repository-name $IMAGE_NAME --region $AWS_REGION --profile $AWS_PROFILE --image-ids imageTag=<tag>`

# Step 7: Installation on the platform (handled by Mass Dynamics)

At this stage, you would need to contact MD Member Success, who will coordinate with the engineering team to have your workflow installed on the platform.

Under the hood, a new workflow is registered via the script `md-dataset-deploy` from the [MD Dataset Package](https://github.com/MassDynamics/md_dataset). For reference, this project includes `./infra` and `./scripts/deploy` with example Helm configurations - these may be useful if you need to automate deployment (e.g. via CI/CD), but installation is typically done by the Mass Dynamics team.

Note: the example deployment scripts do not cover IAM or Kubernetes Service Account setup.