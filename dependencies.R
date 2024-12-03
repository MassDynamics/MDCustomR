install.packages("pkgdown", repos = "http://cran.us.r-project.org")
install.packages('devtools', repos = "http://cran.us.r-project.org")

print("PRINT R SESSION")
print(sessionInfo())

if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

print("PRINT BIOCONDUCTOR VERSION")
print(BiocManager::version())
BiocManager::install("limma")
