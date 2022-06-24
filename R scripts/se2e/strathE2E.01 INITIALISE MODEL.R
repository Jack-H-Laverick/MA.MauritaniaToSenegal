
## Initialise model

library(ggplot2) ; source("./R scripts/@_Region file.R")  # ggplot is needed to source the Region file

R.utils::copyDirectory("../Celtic Sea/Data/Celtic_Sea_ERSEM_4/2003-2013/", 
                       stringr::str_glue("./StrathE2E/{implementation}/2010-2019/")) # Copy example model
