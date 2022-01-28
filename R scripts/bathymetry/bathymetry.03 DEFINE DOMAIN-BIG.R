
# Create an object defining the geographic extent of the model domain

#### Set up ####

rm(list=ls())                                                   

Packages <- c("tidyverse", "sf", "stars", "rnaturalearth", "raster")                  # List handy packages
lapply(Packages, library, character.only = TRUE)                            # Load packages

source("./R scripts/@_Region file.R")                                       # Define project region 

world <- ne_countries(scale = "medium", returnclass = "sf") %>%             # Get a world map
  st_transform(crs = crs)                                                   # Assign polar projection

GEBCO <- raster("../Shared data/GEBCO_2020.nc")
GFW <- raster("../Shared data/distance-from-shore.tif")

crop <- as(extent(-22, -9, 11, 22), "SpatialPolygons")
crs(crop) <- crs(GEBCO)

GEBCO <- crop(GEBCO, crop)
GFW <- crop(GFW, crop)

#### Polygons based on depth ####

Depths <- GEBCO
Depths[GEBCO >= 0 | GEBCO < - 900] <- NA

Depths[Depths < -70] <- -900
Depths[Depths > -70] <- -70

Depths <- st_as_stars(Depths) %>% 
  st_as_sf(merge = TRUE) %>% 
  st_make_valid() %>% 
  group_by(Elevation.relative.to.sea.level) %>% 
  summarise(Depth = abs(mean(Elevation.relative.to.sea.level))) %>% 
  st_make_valid()

ggplot(Depths) +
  geom_sf(aes(fill = Depth), alpha = 0.2) + 
  theme_minimal() 

#### Polygons based on distance ####

Distance <- GFW
Distance[GFW == 0 | GFW > 20] <- NA  # Distance appears to be in KM not m as stated on the website.

Distance[Distance < 20] <- 20  # Distance appears to be in KM not m as stated on the website.

Distance <- st_as_stars(Distance) %>% 
  st_as_sf(merge = TRUE) %>% 
  st_make_valid() %>% 
  group_by(distance.from.shore) %>% 
  summarise(Distance = (mean(distance.from.shore))) %>% 
  st_make_valid()

ggplot() +
  geom_sf(data = Distance) + 
#  geom_sf(data = Depths, aes(fill = Depth), alpha = 0.2) +
  theme_minimal() 

#### Expand inshore and cut offshore ####

inshore <- st_union(Distance, filter(Depths, Depth == 70)) %>% 
  st_make_valid() %>% 
  sfheaders::sf_remove_holes() %>% 
  st_cast("POLYGON") %>% 
  mutate(area = as.numeric(st_area(.))) %>% 
  filter(area == max(area)) %>% 
  dplyr::select(-area)

offshore <- filter(Depths, Depth == 900) %>% 
  sfheaders::sf_remove_holes() %>% 
  st_cast("POLYGON") %>% 
  mutate(area = as.numeric(st_area(.))) %>% 
  filter(area == max(area)) %>% 
  dplyr::select(-area)

sf_use_s2(F)
shrunk <- bind_rows(inshore, offshore) %>%
  st_make_valid() %>% 
  st_difference()

#### Cut to combined EEZs ####

EEZs <- bind_rows(read_sf("./Data/eez_gambia/"),
                  read_sf("./Data/eez_mauritania/"),
                  read_sf("./Data/eez_senegal/")) %>% 
  st_union() %>% 
  st_sf(item = "EEZs")

ggplot() +
  geom_sf(data = EEZs, fill = "red") +
  geom_sf(data = shrunk, aes(fill = Depth), alpha = 0.5)

shrunk <- st_intersection(shrunk, st_transform(EEZs, st_crs(shrunk))) %>% 
  st_make_valid()

ggplot(shrunk) +
  geom_sf(aes(fill = Depth), alpha = 0.5)

#### Format to domains object ####

Domains <- transmute(shrunk, 
                     Shore = ifelse(Depth == 70, "Inshore", "Offshore"),
                     area = as.numeric(st_area(shrunk)),
                     Elevation = exactextractr::exact_extract(GEBCO, shrunk, "mean")) %>% 
  st_transform(crs = crs) %>% 
  group_by(Shore) %>% 
  summarise(Elevation = weighted.mean(Elevation, area),
            area = sum(area))

saveRDS(Domains, "./Objects/Domains.rds")

map <- ggplot() + 
  geom_sf(data = Domains, aes(fill = Shore), colour = NA) +
#  geom_sf(data = Region_mask, colour = "red", fill = NA) + 
  geom_sf(data = world, size = 0.1, fill = "black") +
  scale_fill_manual(values = c(Inshore = "yellow", Offshore = "yellow3"), name = "Zone") +
  zoom +
  theme_minimal() +
  #  theme(axis.text = element_blank()) +
  labs(caption = "Final model area") +
  NULL
ggsave_map("./Figures/bathymetry/Domains.png", map)

map_distance <- ggplot() +
  geom_stars(data = st_as_stars(GFW) %>% st_transform(crs)) +
  geom_sf(data = world, size = 0.1, fill = "white") +
  zoom +
  theme_minimal() +
  NULL
ggsave_map("./Figures/bathymetry/Distance.png", map_distance)

