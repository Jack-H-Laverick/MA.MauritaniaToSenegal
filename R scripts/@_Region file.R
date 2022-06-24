
## Set repeated commands specific to the project region
implementation <- "Mauritania-Senegal"

library(sf)

#EPSG <- rgdal::make_EPSG()
#EPSG2 <- filter(EPSG, str_detect(note, "Mauritania"))
crs <- 4702                                                              # Specify the map projection for the project

lims <- c(xmin = -22, xmax = -9, ymin = 11, ymax = 22)# Specify limits of plotting window, also used to clip data grids

zoom <- coord_sf(xlim = c(lims[["xmin"]], lims[["xmax"]]), ylim = c(lims[["ymin"]], lims[["ymax"]]), expand = FALSE) # Specify the plotting window for SF maps in this region

ggsave_map <- function(filename, plot) {
  ggsave(filename, plot, scale = 1, width = 12, height = 10, units = "cm", dpi = 500)
  
}                             # Set a new default for saving maps in the correct size
pre <- list(scale = 1, width = 12, height = 10, units = "cm", dpi = 500) # The same settings if you need to pass them to a function in MiMeMo.tools

SDepth <- 70                  # Shallow deep boundary
DDepth <- 900                 # Maximum depth

#### bathymetry.5 MODEL DOMAIN ####

shape <- function(matrix) {
  
shape <-  matrix %>% 
  list() %>% 
  st_polygon() %>% 
  st_sfc() %>% 
  st_sf(Region = implementation,.)
  st_crs(shape) <- st_crs(4326)                                        
  shape <- st_transform(shape, crs = crs)
  return(shape)
  
}                      # Convert a matrix of lat-lons to an sf polygon

Region_mask <- matrix(c(-18.5, 31.5,
                        -11, 31.5,
                        -14.5, 27,
                        -18.5, 27,
                        -18.5, 31.5),
                       ncol = 2, byrow = T) %>% 
  list() %>% 
  st_polygon() %>% 
  st_sfc() %>% 
  st_sf(Region = "Mar-Sen",.)
st_crs(Region_mask) <- st_crs(4326)                                        
Region_mask <- st_transform(Region_mask, crs = crs)

#### bounds.2 MAKE TRANSECTS ####

## Polygons to mark which transects are along the open ocean-inshore boundary

Inshore_Ocean1 <- matrix(c(-17.5, -17.5, -16.5, -16.5, -17.5,    # Longitudes
                           11.93, 11.8, 12.3, 12.49, 11.93), ncol = 2, byrow = F) %>% 
  shape()

Inshore_Ocean2 <- matrix(c(-17.9, -17.9, -17, -17, -17.9,
                           20.3, 20.42, 20.82, 20.73, 20.3), ncol = 2, byrow = F) %>% 
  shape()

Inshore_ocean_boundaries <- rbind(Inshore_Ocean1, Inshore_Ocean2)

rm(Inshore_Ocean1, Inshore_Ocean2)

ggplot() +
  geom_sf(data = readRDS("./Objects/Domains.rds"), aes (fill = "Shore")) +
  geom_sf(data = Inshore_ocean_boundaries, fill = NA)

#### expand polygon for sampling rivers ####

river_expansion <- matrix(c(13, 73,
                            0, 80,
                            0, 85,
                            63, 85,
                            73, 77,
                            30, 71,
                            13, 73),
                          ncol = 2, byrow = T) %>% 
  list() %>% 
  st_polygon() %>% 
  st_sfc() %>% 
  st_sf(Region = implementation,.)
st_crs(river_expansion) <- st_crs(4326)                                          
river_expansion <- st_transform(river_expansion, crs = crs)


