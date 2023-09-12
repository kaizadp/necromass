## NECROMASS DATABASE
## functions for exploratory analysis
## 


# packages for map
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)


make_map_all_studies <- function(db_processed){
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

plot_mat_map = function(){
  
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
  
  
  
  
  
  # plot MAT/MAP distribution
  # gg_data_mat_map = 
  db_processed %>% 
    ggplot(aes(x = MAT, y = MAP/10))+
    geom_point(aes(color = ClimateTypes), size = 3)+
    labs(x = "
         Mean annual temperature (°C)",
         y = "Mean annual precipitation (cm)
         ")+
    #  facet_wrap(~Species, ncol = 1)+
    #  scale_color_manual(values = pal_biome, na.translate = F)+
    scale_color_viridis_d(option = "turbo", direction = -1, na.translate = F)+
    theme_kp()+
    theme(legend.position = c(0.25, 0.7),
          #legend.text = element_text(size = 10),
    )+
    guides(color=guide_legend(override.aes=list(size=2)))+
    NULL
  
  list(map_climate_regions_all = map_climate_regions_all,
       gg_data_mat_map = gg_data_mat_map)
  
}

plot_whittaker_biomes = function(){
  #devtools::install_github("valentinitnelav/plotbiomes", force = TRUE)
  library(plotbiomes)
  
  ggplot() +
    # add biome polygons
    geom_polygon(data = Whittaker_biomes,
                 aes(x    = temp_c,
                     y    = precp_cm,
                     fill = biome),
                 # adjust polygon borders
                 colour = "gray98",
                 size   = 1) +
    theme_bw()+
    geom_point(data = db_processed %>% mutate(mat = as.numeric(mat), map_mm = as.numeric(map_mm)), 
               aes(x = mat, y = map_mm/10), 
               size = 2,
               show.legend = F)
  
  
}

#
# explorations ----




db_processed %>% 
  ggplot(aes(x = glu_n_glucosamine_mg_kg))+
  geom_histogram()

db_processed %>% 
  ggplot(aes(x = Longitude, y = mur_n_muramic_acid_mg_kg))+
  geom_point()

db_processed %>% 
  ggplot(aes(y = Latitude, x = mur_n_muramic_acid_mg_kg))+
  geom_point()

db_processed %>% 
  ggplot(aes(y = Latitude, x = Longitude, color = mur_n_muramic_acid_mg_kg))+
  geom_point()


db_processed %>% 
  ggplot(aes(y = Latitude, x = Longitude, color = ClimateTypes))+
  geom_point()

db_processed %>% 
  ggplot(aes(x = ClimateTypes, y = mur_n_muramic_acid_mg_kg))+
  geom_jitter(width = 0.3)

db_processed %>% 
  ggplot(aes(x = tolower(ecosystem), y = mur_n_muramic_acid_mg_kg))+
  geom_jitter(width = 0.3)

db_processed %>% 
  ggplot(aes(x = tolower(ecosystem), y = glu_n_glucosamine_mg_kg))+
  geom_jitter(width = 0.3)
