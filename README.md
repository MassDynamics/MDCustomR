README
================
December 2024

- [Step 1: Develop the R Workflow](#step-1-develop-the-r-workflow)
- [Step 2: Create the Python Runner](#step-2-create-the-python-runner)
- [Step 3: Create a Docker Image](#step-3-create-a-docker-image)
- [Step 4: Create the project.toml file](#step-4-create-the-project.toml-file)
- [Step 5: Deploy to the MD platform](#step-5-deploy-to-the-md-platform)

This repository provides instructions and an example for setting up a
new custom R workflow integrated into the Mass Dynamics ecosystem.

The example in this repository demonstrates how to create a workflow
that modifies an input intensity dataset and returns a new transformed
intensity dataset.

# Step 1: Develop the R Workflow

Create an R workflow, which can either be a package or a simple
function. The example in this repository is implemented as an R package,
with the workflow located at `./R/transformIntensities.R`.

This package depends on the `limma` and `tidyr` R packages.

The main R function should accept an intensity table and a metadata
table as inputs. Additional parameters of your choice can also be
included. The input and output tables must adhere to the standard Mass
Dynamics format for an INTENSITY dataset.

Develop an optional runner function to invoke the main workflow function and
produce the output as a named list. An example of this function is
provided in `./src/md_custom_r/process.R`.

The naming conventions for the output need to be based on the type of
dataset produced.

Currently, only Intensty datasets are supported. For example, the intensity
type needs to return a list including `intensity`, `metadata` and the optional
`runtime_metadata`.

These types can be found in the [MD Dataset Package](https://github.com/MassDynamics/md_dataset)

# Step 2: Create the Python Runner

Write a Python runner, as shown in `./src/md_custom_r/process_r.py`. This script uses
the Mass Dynamics `md_dataset` Python package to prepare the R input and
execute the workflow in Prefect.

In this file, we prepare the dataframes and program arguments provided
to our R Runner function in Step 1.

This function needs to use the `@md_r` python decorator and provide the
`r_file` path and `r_function` provided in Step 1.

The arguments to the function are also important. The second argument is the
custom set of params that can be be used by the R function and also render
the form on the MD platform.

# Step 3: Create a Docker image

See an example, Dockerfile

The base docker image Dockerfiles can be found in [MD Dataset Package](https://github.com/MassDynamics/md_dataset)

# Step 4: Create the project.toml file 

This file provides details about the package, including its versions, dependencies, and authors. For reference, see the example `project.toml`.

Ensure that the `md_dataset` package version is updated to the latest available version if required unless a specific version is explicitly needed.

# Step 5: Deploy to the MD platform

An example can be found in this project using helm.

See the `./infra` directory and `./scripts/deploy`.
