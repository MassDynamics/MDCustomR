library(MDCustomR)

run_transform_intensities <- function(intensity, metadata, normMethod, intensitySource){

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

  output <- transformIntensities(intensities = protein_intensity,
                                 metadata = protein_metadata,
                                 featureColname = "GroupId",
                                 replicateColname = "replicate",
                                 normMethod = normMethod)

  intensity <- output$intensity
  metadata <- output$metadata

  if (!(intensitySource %in% SOURCE_TO_DATA_MAP)) {
    stop(paste0("Invalid intensity source: ", intensitySource))
  }

  data_keys <- SOURCE_TO_DATA_MAP[intensitySource]
  intensity_table_name <- data_keys["intensity"]
  metadata_table_name <- data_keys["metadata"]

  return(list(intensity_table_name = intensity,
              metadata_table_name = metadata,
              runtime_metadata = output$runtimeMetadata))

}
