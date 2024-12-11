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
  dataMerged <- dataLong |>
    dplyr::left_join(intensities, by = c(featureColname, replicateColname))

  # Step 5: Ensure all column names are preserved
  if (!(all(colnames(colnamesIntensities) %in% colnames(dataLong)))) {
    stop("Not all intensities column names are in output")
  }

  # Step 6: Create runtime metadata
  runtimeMetadata <- data.frame(RVersion = sessionInfo()[1]$R.version$version.string,
                                replicateColname = replicateColname,
                                featureColname = featureColname,
                                normMethod = normMethod)

  # Step 7. Return final result
  return(list(
    intensity = dataLong, #name should be fixed
    metadata = metadata, #name should be fixed like this
    runtimeMetadata = runtimeMetadata
  ))
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
  normalized[[featureColname]] <- as.numeric(rownames(normalized))
  return(normalized)
}

#' @keywords internal
#' @noRd
#' @import tidyr
pivotToLong <- function(normalisedData, intensities, replicateColname, featureColname) {
  replicateColumns <- unique(intensities[[replicateColname]])
  dataLong <- normalisedData |>
    pivot_longer(
      all_of(replicateColumns),
      names_to = replicateColname,
      values_to = "NormalisedIntensity"
    )
  return(dataLong)
}


