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
                 linewidth = 1) +
    geom_point(data = db_processed %>% mutate(mat = as.numeric(MAT), map_mm = as.numeric(MAP)), 
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
    dplyr::select(contains("necromass"), ecosystem, ClimateTypes, biome_name)
  
  db_subset %>% 
    ggplot(aes(x = ecosystem, y = microbial_necromass_C))+
    ggdist::stat_halfeye(aes(), 
                         size = 1, alpha = 0.5,
                         position = position_nudge(x = 0.2), width = 0.5, 
                         #slab_color = "black"
    )+
    geom_jitter(aes(), width = 0.1, )  +
    scale_y_continuous(labels = scales::comma)
  
  
}

sample_numbers = function(db_processed){
  
  sample_count_biome = 
    db_processed %>% 
    group_by(ClimateTypes) %>% 
    dplyr::summarise(n = n())
  
  sample_count_ecosystem = 
    db_processed %>% 
    group_by(ecosystem) %>% 
    dplyr::summarise(n = n())
  
  sample_count_depth = 
    db_processed %>% 
    group_by(lyrtop_cm) %>% 
    dplyr::summarise(n = n())

}





for_report = function(){
  
  # ecosystem numbers ----
  db_processed %>% 
    group_by(ecosystem) %>% 
    dplyr::summarise(n = n())
  
  db_processed %>% 
    group_by(ClimateTypes) %>% 
    dplyr::summarise(n = n())
  
  # ecosystem jitter ----
  numbers = 
    db_subset %>% 
    filter(!ecosystem %in% c("meadow", NA)) %>% 
    filter(name == "gluN") %>% 
    filter(!is.na(value)) %>% 
    group_by(ecosystem) %>% 
    dplyr::summarise(n = n())
  
  db_subset %>% 
    filter(!ecosystem %in% c("meadow", NA)) %>% 
    filter(name == "glu_n_glucosamine_mg_kg") %>% 
    filter(!is.na(value)) %>% 
    ggplot(aes(x = ecosystem, y = value,
               fill = ecosystem))+
    geom_boxplot(alpha = 0.5, outlier.colour = NA, show.legend = F)+
    geom_jitter(width = 0.2, size = 0.5, show.legend = F)+
    geom_text(data = numbers, aes(label = paste0("n = ", n), y = -500))+
    # facet_wrap(~name, scales = "free_y")+
    labs(subtitle = "Glucosamine by ecosystem",
         y = "Glucosamine, mg/kg soil")
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  
  
  
  db_necromass = 
    db_processed %>% 
    dplyr::select(mur_n_muramic_acid_mg_kg, glu_n_glucosamine_mg_kg, 
                  Latitude, Longitude, ecosystem, ClimateTypes) %>% 
    mutate(bacterial_necromass_c_mgkg = mur_n_muramic_acid_mg_kg*45,
           fungal_necromass_c_mgkg = ((glu_n_glucosamine_mg_kg/179.17) - (2*mur_n_muramic_acid_mg_kg/251.23))*179.17 * 9)
  
  
  
  
  db_necromass %>% 
    filter(!ecosystem %in% c("meadow", NA)) %>% 
    ggplot(aes(x = ecosystem, y = fungal_necromass_c_mgkg/1000,
               fill = ecosystem))+
    geom_boxplot(alpha = 0.5, outlier.colour = NA, show.legend = F)+
    geom_jitter(width = 0.2, size = 0.5, show.legend = F)+
   # geom_text(data = numbers, aes(label = paste0("n = ", n), y = -500))+
    # facet_wrap(~name, scales = "free_y")+
    labs(subtitle = "Glucosamine by ecosystem",
         y = "Glucosamine, mg/kg soil")
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  
  
  
  
}


# explore depths ----

depth_summary = 
  db_processed %>%
  dplyr::select(lyrtop_cm, lyrbot_cm) %>% 
  mutate_all(as.numeric) %>% 
  mutate(lyrtop_cm = round(lyrtop_cm, digits = -1),
         lyrbot_cm = round(lyrbot_cm, digits = -1)) %>% 
  group_by(lyrtop_cm, lyrbot_cm) %>% 
  dplyr::summarise(n = n()) %>% 
  ungroup() %>% 
  arrange(n, lyrtop_cm, lyrbot_cm)
  
library(scales)
depth_summary %>% 
  ggplot(aes(x = n))+
  geom_segment(aes(y = lyrtop_cm, yend = lyrbot_cm, xend = n,
                   color = interaction(lyrtop_cm, lyrbot_cm)),
               show.legend = F, linewidth = 2)+
  geom_point(aes(y = lyrtop_cm), size = 4)+
  geom_point(aes(y = lyrbot_cm), size = 4)+
  scale_x_continuous(trans = c("log10", "reverse"))+
  scale_y_reverse()
# of the xx datapoints, 2475 data points are in the top 20 cm

