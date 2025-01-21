library(MDCustomR)

run_transform_intensities <- function(intensities, metadata, normMethod){

  print("Package Versions")
  print(packageVersion("MDCustomR"))

  output <- MDCustomR::transformIntensities(intensities = intensities,
                                 metadata = metadata,
                                 featureColname = "GroupId",
                                 replicateColname = "replicate",
                                 normMethod = normMethod)

  return(
    list(
      intensity=output$intensity, # required
      metadata=output$metadata, # required
      runtime_metadata=output$runtimeMetadata # optional
    )
  )
}
