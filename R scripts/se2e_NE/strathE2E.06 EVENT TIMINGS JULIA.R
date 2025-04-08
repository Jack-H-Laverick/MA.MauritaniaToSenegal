
## Overwrite the entries in the example Celtic Sea event timing parameters file

#### Setup ####

rm(list=ls())                                                               # Wipe the brain
library(tidyverse)
library(sf)
source("./R scripts/@_Region file.R")

#### Copy in Julia's SEAPODYM event timing files ####

R.utils::copyDirectory("./Data/Event_timing_SOMAR_SBS/SBS/",              # Copy example model 
                       stringr::str_glue("./StrathE2E/{implementation}/2010-2019/Param/"))