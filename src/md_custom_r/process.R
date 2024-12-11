library(MDCustomR)

run_transform_intensities <- function(intensities, metadata, normMethod, intensitySource){

  SOURCE_TO_DATA_MAP <- list(
    protein = list(
      intensity = "Protein_Intensity",
      metadata = "Protein_Metadata"
    ),
    peptide = list(
      intensity = "Peptide_Intensity",
      metadata = "Peptide_Metadata"
    )
  )


  print("Package Versions")
  print(packageVersion("MDCustomR"))

  output <- MDCustomR::transformIntensities(intensities = intensities,
                                 metadata = metadata,
                                 featureColname = "GroupId",
                                 replicateColname = "replicate",
                                 normMethod = normMethod)

  if (!(intensitySource %in% names(SOURCE_TO_DATA_MAP))) {
    stop(paste0("Invalid intensity source: ", intensitySource))
  }

  data_keys <- SOURCE_TO_DATA_MAP[intensitySource]
  intensity_table_name <- data_keys["intensity"]
  metadata_table_name <- data_keys["metadata"]

  return(list(intensity_table_name = output$intensity,
              metadata_table_name = output$metadata,
              Runtime_Metadata = output$runtimeMetadata))

}
