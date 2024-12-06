from pydantic import Field
from pydantic import conlist
from typing import Literal

from md_dataset.process import md_r
from md_dataset.models.types import BiomolecularSource
from md_dataset.models.types import DatasetType
from md_dataset.models.types import InputParams
from md_dataset.models.types import IntensityInputDataset
from md_dataset.models.types import IntensityTableType
from md_dataset.models.types import RPreparation

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
    "none",
    "scale",
    "quantile",
    "cyclicloess"
  ] = Field(
      title='Normalisation Methods',
      description="Normalisation method passed to the limma normalizeBetweenArrays() function.",
      default='none'
  )


@md_r(r_file="./src/md_custom_r/process.R", r_function="run_transform_intensities")
def prepare_input_transform_intensities(
        input_datasets: conlist(IntensityInputDataset,
                                min_items=1,
                                max_items=1),
        params: MDCustomRParams,
        output_dataset_type: DatasetType) -> RPreparation:

    intensity_source = BiomolecularSource(params.intensity_source)
    intensity_table = input_datasets[0].table(intensity_source, IntensityTableType.INTENSITY)
    metadata_table = input_datasets[0].table(intensity_source, IntensityTableType.METADATA)

    return RPreparation(data_frames = [ \
            intensity_table.data, \
            metadata_table.data], \
            r_args=[params.normalisation_methods, intensity_source.value])
