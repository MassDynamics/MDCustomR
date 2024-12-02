class MDCustomRParams(InputParams):
  intensity_source: Literal[
      "protein",
      "peptide"
  ] = Field(
      title='Intensity Source',
      description="Source table of intensities",
      default='none'
  )

  normalisation_methods: Literal[
    "none"
    "scale"
    "quantile",
    "cyclicloess"
  ] = Field(
      title='Intensity Source',
      description="",
      default='none'
  )

@md_r(r_file="./process.R", r_function="process")
def prepare_test_run_r(input_data_sets: list[InputDataset], params: MDCustomRParams, \
        output_dataset_type: DatasetType) -> RPreparation: 
    return RPreparation(data_frames = [ \
            input_data_sets[0].table_data_by_name("Protein_Intensity"), \
            input_data_sets[0].table_data_by_name("Protein_Metadata")], \
            r_args=[params.message])
