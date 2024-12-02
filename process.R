library(MDCustomR)

protein_intensity <- bojkova2020$protein_intensity
protein_metadata <- bojkova2020$protein_metadata

output <- transformIntensities(intensities = protein_intensity,
                               metadata = protein_metadata,
                               featureColname = "GroupId",
                               replicateColname = "replicate",
                               normMethod = "scale")
