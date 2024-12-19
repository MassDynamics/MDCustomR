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

  print(names(metadata))

  output <- MDCustomR::transformIntensities(intensities = intensities,
                                 metadata = metadata,
                                 featureColname = "GroupId",
                                 replicateColname = "replicate",
                                 normMethod = normMethod)

  return(
    list(
      intensity=output$intensity,
      metadata=output$metadata,
      runtime_metadata=output$runtimeMetadata
    )
  )
}
