hello_world <- function(intensity_dataframe, metadata_dataframe) {
  reversed <- rev(intensity_dataframe)

  more_output <- data.frame(
    Test = c("hello"),
    Message = c("world")
  )

  return_object <- (list(output=reversed, more_output=more_output))
  names(return_object) <- c("intensity", "metadata")

  return(return_object)
}
