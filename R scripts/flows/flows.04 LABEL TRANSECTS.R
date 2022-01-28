
# readRDS("./Objects/Months/.")    # Marker so network script can see where the data is coming from

#### Set up ####

rm(list=ls())                                                               # Wipe the brain
library(MiMeMo.tools)
source("./R scripts/@_Region file.R")                                       # Define project region 

domains <- readRDS("./Objects/Domains.rds")                                 # Load SF polygons of the MiMeMo model domains

Edges <- readRDS("./Objects/Split_boundary.rds") %>%                        # Load in segments of domain boundaries
  mutate(Segment = as.numeric(Segment))

#### Create a NEMO-MEDUSA grid to intersect with transects ####

points <- readRDS("./Objects/Months/NM.01.1980.rds") %>%                    # Import an NM summary object
  filter(slab_layer == "S") %>%                                             # Limit to the shallow layer to avoid duplication (and it's bigger)
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)  %>%            # Set as sf object
  st_transform(crs = crs)

## st_voronoi was erroring because of a (near) regular grid, so I made a regular grid.

cellsize <- c(0.25,0.24)                                                    # Tweak so that the points are roughly centre in the cells across the grid
bottom_left <- st_bbox(grid)[1:2]                                           # Offset so points are in the centre not on an edge

grid <- st_union(points) %>%                                                # Combine              
  st_transform(4326) %>%                                                    # It's easier to specify cell size in lat/lon
  st_make_grid(what = "polygons", 
               cellsize = cellsize,
               offset = c(bottom_left - (cellsize/2)))
             
plot(st_transform(st_geometry(domains), crs = 4326), col = "grey")          # Keep tweaking until this looks right
plot(grid, border = 'green', pch=1, add = TRUE)
plot(st_transform(points, 4326), add = TRUE, cex = 0.3)

grid <- sf::st_sf(grid) %>%                                                 # Reinstate sf formatting
  st_transform(crs = crs) %>%                                               # Back to project crs
  st_join(points) %>%                                                       # Rejoin meta-data from points
  arrange(x, y)                                                             # Order the polygons to match the points

ggplot(grid) +                                                              # Check the polygons match correctly with points
  geom_sf(aes(fill = Temperature), size = 0.05, colour = "white") +
  geom_sf(data = Edges, colour = "orange") +
  zoom +
  theme_minimal() +
  labs(caption = "If the spatial pattern looks right, polygons and domain are matched") +
  NULL

ggsave("./Figures/flows/check.04.1.png", bg = "white")

#### Characterise transects (weights, target current, nature of water exchanges) ####

labelled <- st_intersection(st_make_valid(Edges), st_make_valid(grid)) %>% 
  mutate(split_length = as.numeric(st_length(.))) %>% 
  select(x, y, slab_layer, Shore, split_length, Bathymetry) %>% 
  filter(split_length != 0) %>% 
  characterise_flows(domains, precision = 1000000) %>%                            # In which direction? (in or out of box and with which neighbour)
  filter(Neighbour != "Offshore")                                               # Offshore as a neighbour is a rare artefact from resolution.

ggplot(labelled) +                                                              # Check segments are labelled
  geom_sf(aes(colour = Neighbour)) +
  viridis::scale_colour_viridis(option = "viridis", na.value = "red", discrete = T) +
  zoom +
  labs(caption = "Check the transects are correctly labelled by zone") +
  theme_minimal()

ggsave("./Figures/flows/check.04.2.png", bg = "white")

shallow <- mutate(labelled,
                  thickness = ifelse(Bathymetry >= SDepth, SDepth, Bathymetry),
                  weights = thickness*split_length) %>% 
  st_drop_geometry() %>% 
  select(-c(thickness, Bathymetry, split_length))

deep <- mutate(labelled, 
               slab_layer = "D",
               thickness = ifelse(Bathymetry > DDepth, (DDepth-SDepth), (Bathymetry-SDepth)),
               weights = thickness*split_length) %>% 
  st_drop_geometry() %>% 
  select(-c(thickness, Bathymetry, split_length))

#### Mark transects for different summaries ####

water_exchanges <- bind_rows(filter(shallow, Shore == "Offshore" | Neighbour != "Offshore"), # Drop Inshore to Offshore transects(avoid double accounting with Offshore to inshore transects)
                        filter(deep, Shore == "Offshore" & Neighbour == "Ocean"))      # The deep layer of the model only has exchange between offshore and the sea (and a vertical component dealt with separately)

boundary_conditions <- bind_rows(filter(shallow, Neighbour == "Ocean"),                # Keep only transects on the domain perimeter
                        filter(deep, Shore == "Offshore" & Neighbour == "Ocean")) %>%  # The deep layer of the model only has exchange between offshore and the sea
  mutate(perimeter = T)

test <- anti_join(boundary_conditions, water_exchanges)                                # Check boundary transects are a subset of water_exchange transects          

Transects <- left_join(water_exchanges, boundary_conditions)                           # Attach column indicating rows to drop when sumarising the boundary

data.table::setDT(Transects, key = c("x", "y", "slab_layer"))                 # Convert to a data.table keyed spatially for quick summaries.

saveRDS(Transects, "./Objects/Boundary_transects.rds")
