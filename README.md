# README

December 2024

- [Step 1: Develop the R Workflow](#step-1-develop-the-r-workflow)
- [Step 2: Define Dependencies](#step-2-define-dependencies)
- [Step 3: Create the Python Runner](#step-3-create-the-python-runner)
- [Step 4: Local Validation and Testing](#step-4-local-validation-and-testing)
- [Step 5: Create the pyproject.toml file](#step-5-create-the-pyprojecttoml-file)
- [Step 6: Create a Docker Image](#step-6-create-a-docker-image)
- [Installation on the platform (handled by Mass Dynamics)](#installation-on-the-platform-handled-by-mass-dynamics)

This repository provides instructions and an example for setting up a
new custom R workflow integrated into the Mass Dynamics ecosystem.

The example in this repository demonstrates how to create a workflow
that modifies an input intensity dataset and returns a new transformed
intensity dataset.

# Step 1: Develop the R Workflow

Create an R workflow, which can either be a package or a simple
function. You need a main workflow function and an R runner function
(e.g. `process.R`) — for packages this loads the package and calls the main function; for scripts the runner can live in the same file. If using an R package, include a `DESCRIPTION` with version constraints for dependencies.

The example in this repository is implemented as an R package,
with the workflow located at `./R/transformIntensities.R`. This package depends on the `limma` and `tidyr` R packages.

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

Your workflow can produce any of these dataset types. The R output list structure must match the type.

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

# Step 6: Create a Docker image

Create a `Dockerfile` — this file is required for deployment. See the example `Dockerfile` in this repository.

**Dockerfile structure: R package vs R script**

For an R package: `COPY` `DESCRIPTION`, `install.R`, `NAMESPACE`, `src/`, `R/`, then run `install.R`.

For an R script: `COPY` the R script(s) only; no `install.R` step. Use `dependencies.R` to install packages.

The base docker image Dockerfiles can be found in [MD Dataset Package](https://github.com/MassDynamics/md_dataset).

When using local docker images built using the [MD Dataset Package](https://github.com/MassDynamics/md_dataset) in `scripts/local-docker-images`
you can use the following to build the provided example:

```sh
docker build --build-arg BASE_IMAGE=md_dataset_package-linux-r-base:latest -t md_custom-r-linux:latest -f Dockerfile --platform="linux/amd64" .
```

# Installation on the platform (handled by Mass Dynamics)

At this stage, you would need to contact MD Member Success, who will coordinate with the engineering team to have your workflow installed on the platform.

Under the hood, a new workflow is registered via the script `md-dataset-deploy` from the [MD Dataset Package](https://github.com/MassDynamics/md_dataset). For reference, this project includes `./infra` and `./scripts/deploy` with example Helm configurations - these may be useful if you need to automate deployment (e.g. via CI/CD), but installation is typically done by the Mass Dynamics team.

Note: the example deployment scripts do not cover IAM or Kubernetes Service Account setup.