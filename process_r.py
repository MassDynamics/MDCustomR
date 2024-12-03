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


SOURCE_TO_DATA_MAP = {
        "protein": {
            "intensity": "Protein_Intensity",
            "metadata": "Protein_Metadata"
        },
        "peptide": {
            "intensity": "Peptide_Intensity",
            "metadata": "Peptide_Metadata"
        }
    }


@md_r(r_file="./process.R", r_function="run_transform_intensities")
def prepare_input_transform_intensities(input_data_sets: list[InputDataset], params: MDCustomRParams, \
        output_dataset_type: DatasetType) -> RPreparation: 
          
    intensity_source = params.intensity_source
    if intensity_source not in SOURCE_TO_DATA_MAP:
      raise ValueError(f"Invalid intensity source: {intensity_source}")
  
    data_keys = SOURCE_TO_DATA_MAP[intensity_source]
    intensity_table_name = data_keys["intensity"]
    metadata_table_name = data_keys["metadata"]
          
    return RPreparation(data_frames = [ \
            intensity_table_name, \
            metadata_table_name, \
            r_args=[params.normalisation_methods, intensity_source])
