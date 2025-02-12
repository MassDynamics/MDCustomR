from pydantic import Field
from pydantic import conlist
from typing import Literal

from md_dataset.process import md_r
from md_dataset.models.dataset import DatasetType
from md_dataset.models.dataset import InputParams
from md_dataset.models.dataset import IntensityInputDataset
from md_dataset.models.dataset import IntensityTableType
from md_dataset.models.r import RFuncArgs

class MDCustomRParams(InputParams):
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
def input_transform_intensities(
        input_datasets: conlist(IntensityInputDataset,
                                min_length=1,
                                max_length=1),
        params: MDCustomRParams,
        output_dataset_type: DatasetType) -> RFuncArgs:

    intensity_table = input_datasets[0].table(IntensityTableType.INTENSITY)
    metadata_table = input_datasets[0].table(IntensityTableType.METADATA)

    return RFuncArgs(data_frames = [ \
            intensity_table.data, \
            metadata_table.data], \
            r_args=[params.normalisation_methods])
