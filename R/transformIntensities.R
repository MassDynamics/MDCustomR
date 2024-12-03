#' Transform intensities
#'
#' @param intensitiesTable data.frame. Mass Dynamics intensities table.
#' @param featuresMetadataTable data.frame Mass Dynamics metadata table.
#' @param featureColname str Name of feature column name in `intensitiesTable` and `featuresMetadataTable`.
#' @param replicateColname str Name of replicate column name in `intensitiesTable`.
#' @param normMethod str Normalisation method to pass to `limma::normalizeBetweenArrays`.
#'
#' @export transformIntensities
transformIntensities <- function(intensitiesTable,
                                 featuresMetadataTable,

                                 featureColname = "GroupId",
                                 replicateColname = "replicate",
                                 normMethod) {
  colnamesIntensities <- colnames(intensitiesTable)

  # Step 1: Pivot to wide format
  dataWide <- pivotToWide(intensitiesTable, featureColname, replicateColname)

  # Step 2: Normalize data
  normalizedData <- normalizeData(dataWide, normMethod, featureColname)

  # Step 3: Pivot back to long format
  dataLong <- pivotToLong(normalizedData, intensitiesTable, replicateColname, featureColname)

  # Step 4: Merge with initial data
  dataMerged <- dataLong |>
    left_join(intensitiesTable, by = c(featureColname, replicateColname))

  # Step 5: Ensure all column names are preserved
  if (!(all(colnames(colnamesIntensities) %in% colnames(dataLong)))) {
    stop("Not all intensities column names are in output")
  }

  # Step 6: Create runtime metadata
  runtimefeaturesMetadataTable <- data.frame(RVersion = sessionInfo()[1]$R.version$version.string,
                                replicateColname = replicateColname,
                                featureColname = featureColname,
                                normMethod = normMethod)

  # Step 7. Return final result
  return(list(
    intensity = dataLong, #name should be fixed
    metadata = featuresMetadataTable, #name should be fixed like this
    runtimeMetadata = runtimeMetadata
  ))
}


#' @keywords internal
#' @noRd
#' @import tidyr
pivotToWide <- function(intensitiesTable, featureColname, replicateColname) {
  dataWide <- intensitiesTable |>
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
  normalized[[featureColname]] <- as.numeric(rownames(normalized))
  return(normalized)
}

#' @keywords internal
#' @noRd
#' @import tidyr
pivotToLong <- function(normalisedData, intensitiesTable, replicateColname, featureColname) {
  replicateColumns <- unique(intensitiesTable[[replicateColname]])
  dataLong <- normalisedData |>
    pivot_longer(
      all_of(replicateColumns),
      names_to = replicateColname,
      values_to = "NormalisedIntensity"
    )
  return(dataLong)
}


