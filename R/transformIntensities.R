#' Transform intensities
#'
#' @param intensities data.frame. Mass Dynamics intensities table.
#' @param metadata data.frame Mass Dynamics metadata table.
#' @param featureColname str Name of feature column name in `intensities` and `metadata`.
#' @param replicateColname str Name of replicate column name in `intensities`.
#' @param normMethod str Normalisation method to pass to `limma::normalizeBetweenArrays`.
#'
#' @import dplyr
#' @export transformIntensities
transformIntensities <- function(intensities,
                                 metadata,

                                 featureColname = "GroupId",
                                 replicateColname = "replicate",
                                 normMethod) {
  colnamesIntensities <- colnames(intensities)

  # Step 1: Pivot to wide format
  dataWide <- pivotToWide(intensities, featureColname, replicateColname)

  # Step 2: Normalize data
  normalizedData <- normalizeData(dataWide, normMethod, featureColname)

  # Step 3: Pivot back to long format
  dataLong <- pivotToLong(normalizedData, intensities, replicateColname, featureColname)

  # Step 4: Merge with initial data
  intensities$NormalisedIntensity <- NULL
  dataMerged <- dataLong |>
    dplyr::left_join(intensities, by = c(featureColname, replicateColname))

  # Step 5: Ensure all column names are preserved & respect the initial order
  if (!(all(colnamesIntensities %in% colnames(dataMerged)))) {
    stop("Not all intensities column names are in output")
  }

  dataMerged <- dataMerged[, colnamesIntensities]

  # Step 6: Create runtime metadata
  runtimeMetadata <- data.frame(RVersion = sessionInfo()[1]$R.version$version.string,
                                replicateColname = replicateColname,
                                featureColname = featureColname,
                                normMethod = normMethod)

  # Step 7. Return final result
  metadata <- convertNAToStrings(metadata)
  return(list(
    intensity = dataMerged, #name should be fixed
    metadata = metadata, #name should be fixed like this
    runtimeMetadata = runtimeMetadata
  ))
}




#' Convert columns to characters and NA to strings
#'
#' @description This is needed for the parquet conversion
#' @keywords internal
convertNAToStrings <- function(outputTable){
  metadataColumns <- c("GeneNames", "GroupLabel", "GroupLabelType", "ProteinIds", "Description")
  for(metaCol in metadataColumns){
    if(metaCol %in% colnames(outputTable)){
      outputTable[[metaCol]] <- as.character(outputTable[[metaCol]])
      outputTable[[metaCol]][is.na(outputTable[[metaCol]])] <-  ""
    }
  }
  return(outputTable)
}



#' @keywords internal
#' @noRd
#' @import tidyr
pivotToWide <- function(intensities, featureColname, replicateColname) {
  dataWide <- intensities |>
    pivot_wider(
      id_cols = featureColname,
      names_from = replicateColname,
      values_from = "NormalisedIntensity"
    ) |>
    as.data.frame()

  rownames(dataWide) <- dataWide$GroupId
  dataWide$GroupId <- NULL
  return(dataWide)
}

#' @keywords internal
#' @noRd
#' @import limma
normalizeData <- function(dataWide, normMethod, featureColname) {
  normalized <- data.frame(
    limma::normalizeBetweenArrays(log2(dataWide), method = normMethod)
  )
  colnames(normalized) <- colnames(dataWide)
  normalized[[featureColname]] <- as.numeric(rownames(normalized))
  return(normalized)
}

#' @keywords internal
#' @noRd
#' @import tidyr
#' @import tidyselect
pivotToLong <- function(normalisedData, intensities, replicateColname, featureColname) {
  replicateColumns <- unique(intensities[[replicateColname]])

  dataLong <- normalisedData |>
    pivot_longer(
      tidyselect::all_of(replicateColumns),
      names_to = replicateColname,
      values_to = "NormalisedIntensity"
    )
  return(dataLong)
}


