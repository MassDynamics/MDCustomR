README
================
December 2024

- [Step 1: Develop the R Workflow](#step-1-develop-the-r-workflow)
- [Step 2: Implement the Runner
  Function](#step-2-implement-the-runner-function)
- [Step 3: Create the Python Runner](#step-3-create-the-python-runner)

This repository provides instructions and an example for setting up a
new custom R workflow integrated into the Mass Dynamics ecosystem.

The example in this repository demonstrates how to create a workflow
that modifies an input intensity dataset and returns a new transformed
intensity dataset.

# Step 1: Develop the R Workflow

Create an R workflow, which can either be a package or a simple
function. The example in this repository is implemented as an R package,
with the workflow located at `./R/transformIntensities.R`. This package
depends on the `limma` and `tidyr` R packages.

The main R function should accept an intensity table and a metadata
table as inputs. Additional parameters of your choice can also be
included. The input and output tables must adhere to the standard Mass
Dynamics format for an INTENSITY dataset.

# Step 2: Implement the Runner Function

Develop a runner function to invoke the main workflow function and
produce the output as a named list. An example of this function is
provided in `./process.R`.

The naming conventions for the output, particularly when generating a
new intensity dataset, should follow the recommendations specified in
the `SOURCE_TO_DATA_MAP` list.

# Step 3: Create the Python Runner

Write a Python runner, as shown in `./process_r.py`. This script uses
the Mass Dynamics `md_dataset` Python package to prepare the R input and
execute the workflow in Prefect.

In this file, define and document the workflow’s input arguments to
ensure clarity and consistency.
