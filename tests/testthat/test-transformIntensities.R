library(testthat)
library(MDCustomR)


testthat::test_that("transformIntensities is running", {
  intensities <- bojkova2020$protein_intensity
  metadata <- bojkova2020$protein_metadata
  metadata$Description <- NA

  output <- transformIntensities(intensities = intensities,
                                   metadata = metadata,
                                   featureColname = "GroupId",
                                   replicateColname = "replicate",
                                   normMethod = "scale")

  expect_true(length(output) == 3)
  expect_true(all(names(output) == c("intensity", "metadata", "runtimeMetadata")))

})

testthat::test_that("transformIntensities is running with special characters", {
  intensities <- bojkova2020$protein_intensity
  intensities$replicate <- gsub("_", "-", intensities$replicate)
  metadata <- bojkova2020$protein_metadata
  metadata$Description <- NA

  output <- transformIntensities(intensities = intensities,
                                 metadata = metadata,
                                 featureColname = "GroupId",
                                 replicateColname = "replicate",
                                 normMethod = "scale")

  expect_true(length(output) == 3)
  expect_true(all(names(output) == c("intensity", "metadata", "runtimeMetadata")))

})


testthat::test_that("transformIntensities is converting NAs to empty strings", {
  intensities <- bojkova2020$protein_intensity
  metadata <- bojkova2020$protein_metadata
  metadata$GeneNames[1:10] <- NA
  metadata$Description <- NA

  output <- transformIntensities(intensities = intensities,
                                 metadata = metadata,
                                 featureColname = "GroupId",
                                 replicateColname = "replicate",
                                 normMethod = "scale")

})

