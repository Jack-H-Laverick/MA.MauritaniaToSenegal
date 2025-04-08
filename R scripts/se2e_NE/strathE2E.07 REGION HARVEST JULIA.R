
## Overwrite the entries in the example Celtic Sea event timing parameters file

#### Setup ####

rm(list=ls())                                                               # Wipe the brain
library(tidyverse)
library(sf)
source("./R scripts/@_Region file.R")

#### Copy in Julia's SEAPODYM event timing files ####

R.utils::copyFile(stringr::str_glue("./Data/Region_harvest_SOMAR_SBS/region_harvest_r_{toupper(implementation)}_2010-2019.csv"),              # Copy example model 
                  stringr::str_glue("./StrathE2E/{implementation}/2010-2019/Target/region_harvest_r_{toupper(implementation)}_2010-2019.csv"))