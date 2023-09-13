## NECROMASS DATABASE
## functions for exploratory analysis
## 


# packages for map
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)


make_map_all_studies <- function(db_processed){
  
  # mapping all MAT-MAP data points ----
  KoeppenGeigerASCII = readxl::read_xlsx("1-data/geographic_databases/KoeppenGeigerASCII.xlsx")
  # KG climate zone map of all the globe
  map_climate_regions_all = 
    KoeppenGeigerASCII %>% 
    mutate(ClimateTypes = case_when(grepl("A", ClimateTypes) ~ "equatorial",
                                    grepl("B", ClimateTypes) ~ "arid",
                                    grepl("C", ClimateTypes) ~ "temperate",
                                    grepl("D", ClimateTypes) ~ "snow",
                                    grepl("E", ClimateTypes) ~ "polar")) %>% 
    #  reorder_biome_levels() %>% 
    ggplot(aes(x = Longitude, y = Latitude, color = ClimateTypes))+
    geom_point()+
    scale_color_viridis_d(option = "turbo", direction = -1, na.translate = F)+
    labs(color = "",
         x = "",
         y = "")+
    theme_kp()+
    theme(axis.text = element_blank(),
          panel.grid = element_blank(),
          axis.ticks = element_blank())+
    NULL
  
  # mapping our data distribution ----
  world <- ne_countries(scale = "medium",  returnclass = "sf", type = "countries")
  
  sndb_map_data = 
    db_processed %>% 
    distinct(Latitude, Longitude, ClimateTypes) %>% 
    drop_na()
  
  world %>% 
    ggplot()+
    geom_sf(color = NA, alpha = 0.7)+
    geom_point(data = sndb_map_data,
               aes(x = Longitude, y = Latitude,
                   color = ClimateTypes), 
               size = 2)+
    labs(color = "",
         x = "",
         y = "")+
    scale_color_viridis_d(option = "turbo", direction = -1, na.translate = F)+
    #theme_void()+
    theme_kp()+
    theme(axis.text = element_blank(),
          legend.position = "top")+
    guides(colour = guide_legend(nrow = 1))+
    NULL
  
}

plot_mat_map = function(db_processed){
  
  # plot MAT/MAP distribution
  db_processed %>% 
    ggplot(aes(x = MAT, y = MAP/10))+
    geom_point(aes(color = ClimateTypes), size = 3)+
    labs(x = "
         Mean annual temperature (°C)",
         y = "Mean annual precipitation (cm)
         ")+
    scale_color_viridis_d(option = "turbo", direction = -1, na.translate = F)+
    theme_kp()+
    theme(legend.position = c(0.15, 0.8))+
    NULL

}

plot_whittaker_biomes = function(db_processed){
  # devtools::install_github("valentinitnelav/plotbiomes", force = TRUE)
  # library(plotbiomes)
  
  ggplot() +
    # add biome polygons
    geom_polygon(data = Whittaker_biomes,
                 aes(x    = temp_c,
                     y    = precp_cm,
                     fill = biome),
                 # adjust polygon borders
                 colour = "gray98",
                 size   = 1) +
    geom_point(data = db_processed %>% mutate(mat = as.numeric(mat), map_mm = as.numeric(map_mm)), 
               aes(x = mat, y = map_mm/10), 
               size = 2,
               show.legend = F)+
    labs(x = "
         Mean annual temperature (°C)",
         y = "Mean annual precipitation (cm)
         ")+
    theme_kp()+
    theme(legend.position = "right")
  
}

#
# explorations ----

plot_jitters = function(db_processed){
  # explorations by different variables to see spread

  db_subset <- 
    db_processed %>% 
    dplyr::select(mur_n_muramic_acid_mg_kg, glu_n_glucosamine_mg_kg, 
                  Latitude, Longitude, ecosystem, ClimateTypes) %>% 
    pivot_longer(cols = c(mur_n_muramic_acid_mg_kg, glu_n_glucosamine_mg_kg)) %>% 
    filter(!is.na(value))
  
  lon = 
    db_subset %>% 
    ggplot(aes(x = Longitude, y = value))+
    geom_point()+
    facet_wrap(~name, scales = "free_y")
  
  lat = 
    db_subset %>% 
    ggplot(aes(y = Latitude, x = value))+
    geom_point()+
    facet_wrap(~name, scales = "free_x")
  
  ecosystem = 
    db_subset %>% 
    ggplot(aes(x = ecosystem, y = value))+
    geom_jitter()+
    facet_wrap(~name, scales = "free_y")+
    labs(subtitle = "by ecosystem")+
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  climate = 
    db_subset %>% 
    ggplot(aes(x = ClimateTypes, y = value))+
    geom_jitter()+
    facet_wrap(~name, scales = "free_y")+
    labs(subtitle = "by KoeppenGeiger climate")+
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  list(lat = lat,
       lon = lon,
       ecosystem = ecosystem,
       climate = climate)
}



