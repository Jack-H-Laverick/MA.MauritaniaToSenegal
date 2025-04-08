
## Initialise model

library(ggplot2) ; source("./R scripts/@_Region file.R") # ggplot2 is needed to source the Region file

R.utils::copyDirectory("./Data/Brazilian_shelf_v2/Brazilian_shelf/2010-2019/",              # Copy example model 
                       stringr::str_glue("./StrathE2E/{implementation}/2010-2019/"))    # Into new implementation

dir.create("./StrathE2E/Results")                                                       # Create results folder for model runs
  