library(testthat)
library(MDCustomR)


testthat::test_that("transformIntensities is running", {
  intensities <- bojkova2020$protein_intensity
  metadata <- bojkova2020$protein_metadata

  output <- transformIntensities(intensities = intensities,
                                   metadata = metadata,
                                   featureColname = "GroupId",
                                   replicateColname = "replicate",
                                   normMethod = "scale")

  expect_true(length(output) == 3)
  expect_true(all(names(output) == c("intensity", "metadata", "runtimeMetadata")))

})

