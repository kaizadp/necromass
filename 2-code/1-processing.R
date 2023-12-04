## NECROMASS DATABASE
## functions to clean and process the necromass data
## 


# initial processing/data download
db_gsheets = read_sheet("1nQc80bapNh3LI50Fdn-ybvKbSyyMs2jpc5SWMJ3Hy4c", 
                        sheet = "database", col_types = "c")

# clean up the database ----
clean_lat_lon = function(dat){
  dat %>% 
    #dplyr::select(Latitude, Longitude) %>% 
    
    # first, clean up ----
  mutate(
    # clean up f-ing latitude/longitude
    Latitude = str_replace(Latitude, " N", "N"),
    Latitude = str_replace(Latitude, " S", "S"),
    Longitude = str_replace(Longitude, " E", "E"),
    Longitude = str_replace(Longitude, " W", "W"),
    
    Latitude = str_replace(Latitude, " N", "N"),
    Latitude = str_replace(Latitude, " S", "S"),
    Longitude = str_replace(Longitude, " E", "E"),
    Longitude = str_replace(Longitude, " W", "W"),
    
    Latitude  = str_replace(Latitude, "′′", '"'),
    Longitude  = str_replace(Longitude, "′′", '"'),
    
    Latitude  = str_replace(Latitude, "″", '"'),
    Longitude  = str_replace(Longitude, "″", '"'),
    
    Latitude  = str_replace(Latitude, "′", "'"),
    Longitude  = str_replace(Longitude, "′", "'")
  ) %>% 
    
    # LATITUDE ----
  # a. remove any spaces, so they don't fuck up the analysis later
  # assign negative values to S hemisphere
  # and then delete N/S from the Latitude column
  mutate(Latitude = str_remove(Latitude, " "),
         Latitude = if_else(grepl("S", Latitude), 
                            paste0("-", Latitude), 
                            Latitude),
         Latitude = str_remove(Latitude, "[A-Z]")) %>% 
    
    # b. check if the Latitude is already in decimal form
    # and separate into different columns
    # if the minutes symbol is present, then it needs to be converted
    mutate(latitude_dec = if_else(grepl("'", Latitude), 
                                  NA_character_,
                                  Latitude),
           latitude_deg = if_else(grepl("'", Latitude), 
                                  Latitude,
                                  NA_character_),
           # the latitude_dec may have some straggler _, remove
           latitude_dec = parse_number(latitude_dec)) %>% 
    
    # c. check the Latitude column for completeness of DD MM SS
    # if seconds are not reported, assume 00 sec
    mutate(latitude_deg = if_else(grepl('"', latitude_deg), 
                                  latitude_deg, 
                                  str_replace_all(latitude_deg, "'", "'00"))) %>% 
    
    # d. replace all degree, minute, second symbols with spaces
    mutate(
      latitude_deg = str_replace_all(latitude_deg, "°", " "),
      latitude_deg = str_replace_all(latitude_deg, "'", " "),
      latitude_deg = str_replace_all(latitude_deg, '"', " ")) %>% 
    
    # e. finally, do the conversion
    # then merge the latitude_dec and lat columns and format
    rowwise() %>% 
    mutate(lat = measurements::conv_unit(latitude_deg, 
                                         from = "deg_min_sec", 
                                         to = "dec_deg")) %>% 
    mutate(Latitude_corrected = case_when(!is.na(latitude_dec) ~ latitude_dec,
                                          !is.na(lat) ~ as.numeric(lat)),
           Latitude_corrected = round(Latitude_corrected, 3)) %>% 
    
    # LONGITUDE ----
  # a. remove any spaces, so they don't fuck up the analysis later
  # assign negative values to S hemisphere
  # and then delete N/S from the Longitude column
  mutate(Longitude = str_remove(Longitude, " "),
         Longitude = if_else(grepl("W", Longitude), 
                             paste0("-", Longitude), 
                             Longitude),
         Longitude = str_remove(Longitude, "[A-Z]")) %>% 
    
    # b. check if the Longitude is already in decimal form
    # and separate into different columns
    # if the minutes symbol is present, then it needs to be converted
    mutate(longitude_dec = if_else(grepl("'", Longitude), 
                                   NA_character_,
                                   Longitude),
           longitude_deg = if_else(grepl("'", Longitude), 
                                   Longitude,
                                   NA_character_),
           # the longitude_dec may have some straggler _, remove
           longitude_dec = parse_number(longitude_dec)) %>% 
    
    # c. check the Longitude column for completeness of DD MM SS
    # if seconds are not reported, assume 00 sec
    mutate(longitude_deg = if_else(grepl('"', longitude_deg), 
                                   longitude_deg, 
                                   str_replace_all(longitude_deg, "'", "'00"))) %>% 
    
    # d. replace all degree, minute, second symbols with spaces
    mutate(
      longitude_deg = str_replace_all(longitude_deg, "°", " "),
      longitude_deg = str_replace_all(longitude_deg, "'", " "),
      longitude_deg = str_replace_all(longitude_deg, '"', " ")) %>% 
    
    # e. finally, do the conversion
    # then merge the longitude_dec and lat columns and format
    rowwise() %>% 
    mutate(lon = measurements::conv_unit(longitude_deg, 
                                         from = "deg_min_sec", 
                                         to = "dec_deg")) %>% 
    mutate(Longitude_corrected = case_when(!is.na(longitude_dec) ~ longitude_dec,
                                           !is.na(lon) ~ as.numeric(lon)),
           Longitude_corrected = round(Longitude_corrected, 3)) %>% 
    
    dplyr::select(-c("Latitude", "Longitude", "latitude_dec", "latitude_deg", "lat",
                     "longitude_dec", "longitude_deg", "lon")) %>% 
    rename(Latitude = Latitude_corrected,
           Longitude = Longitude_corrected)
  
}
assign_climate_biome = function(dat){
  
  UDel_summarized_climate = read.csv("1-data/geographic_databases/UDel_summarized_climate.csv")
  KoeppenGeigerASCII = readxl::read_xlsx("1-data/geographic_databases/KoeppenGeigerASCII.xlsx")
  
  dat_mat_map = 
    dat %>% 
    mutate(Latitude2 = round(Latitude*2)/2,
           Longitude2 = round(Longitude*2)/2,
           Lat_dif = ifelse(Latitude2 - Latitude >=0, 0.25, -0.25),
           Lon_dif = ifelse(Longitude2 - Longitude >=0, 0.25, -0.25),
           Latitude2 = Latitude2 - Lat_dif,
           Longitude2 = Longitude2 - Lon_dif) %>% 
    dplyr::select(-Lat_dif, -Lon_dif) %>% 
    left_join(UDel_summarized_climate, by=c("Latitude2"="Latitude", "Longitude2"="Longitude")) %>% 
    left_join(KoeppenGeigerASCII, by=c("Latitude2"="Latitude", "Longitude2"="Longitude")) %>% 
    mutate(ClimateTypes = case_when(grepl("A", ClimateTypes) ~ "equatorial",
                                    grepl("B", ClimateTypes) ~ "arid",
                                    grepl("C", ClimateTypes) ~ "temperate",
                                    grepl("D", ClimateTypes) ~ "snow",
                                    grepl("E", ClimateTypes) ~ "polar")) %>% 
    dplyr::select(-Latitude2, -Longitude2)
  
  
}

clean_db = function(db_gsheets){
  
  # assign rownumbers to records and then remove 
  
  db_select_columns <- 
    db_gsheets %>% 
  #  janitor::clean_names() %>% 
    rownames_to_column("rownumber") %>% 
  #  pivot_longer(cols = -c(rownumber)) %>% 
  #  drop_na() %>% 
  #  pivot_wider() %>% 
    dplyr::select(
      rownumber, author, author_doi, sample, notes,
      treatment, treatment_level,
      latitude, longitude, lat_lon_notes, elevation_m, depth_cm, horizon,
      soil_type, ecosystem, wetland_type, plant_species, 
      year_sampled,
      fraction_scheme, aggregate_size,
      amino_sugars, gluN, murA, galN, manN, 
      microbial_necromass_C, fungal_necromass_C, bacterial_necromass_C,
      microbial_biomass_C, microbial_biomass_N, fungal_biomass_C, bacterial_biomass_C,
      soc, soil_C, soil_N,
      pH, pH_method, clay, silt, sand
    ) %>% 
  #  filter(!is.na(gluN) | !is.na(murA) | !is.na(galN) | !is.na(manN)) %>% 
    force()
  
  db_processed <- 
    db_select_columns %>% 
    mutate_at(vars(c(gluN, murA, latitude, longitude)), as.numeric) %>% 
    rename(Latitude = latitude, Longitude = longitude) %>% 
    clean_lat_lon() %>% 
    assign_climate_biome() %>% 
    mutate(ecosystem = tolower(ecosystem))
  
  ## PROCESSING AND CALCULATING NECROMASS COLUMNS
  db_necromass = 
    db_select_columns %>% 
    dplyr::select(rownumber, gluN, murA, galN, manN, contains("necromass")) %>% 
    mutate_all(as.numeric) %>% 
    column_to_rownames("rownumber") %>% 
    janitor::remove_empty("rows") %>% 
    rownames_to_column("rownumber")
    
  db_necromass2 = 
    db_necromass %>% 
    mutate(AS_data = (!is.na(gluN|galN|murA|manN)),
           necro_data = !is.na(bacterial_necromass_C|fungal_necromass_C))
  
  db_necromass_as = 
    db_necromass2 %>% 
    filter(AS_data) %>% 
## ^need to calculate FNC and BNC and MNC from these
    mutate(bacterial_necromass_C2 = murA * 45,
           fungal_necromass_C2 = ((gluN/179.17) - (2 * murA/251.23)) * 179.17 * 9)
    
    
  db_necromass_fnc_bnc = 
    db_necromass2 %>% 
    filter(necro_data & !AS_data)
## ^need to back-calculate gluN and murA?? -- probably not  
  
  db_necromass_mnc = 
    db_necromass2 %>% 
    filter(!is.na(microbial_necromass_C) & !AS_data & !necro_data)
## ^ leave untouched
  

}

testing = function(){
x = 
  cr_works(dois = "10.7710/2162-3309.1252") %>%
  purrr::pluck("data") %>% dplyr::select(author, published.online, title)

x2 = x %>% purrr::pluck("author") 


author = as.data.frame(x$author)[1,"family"] 
date = x$published.online

x = cr_cn(dois = "10.7710/2162-3309.1252")



doi_df = tribble(
  ~doi,
  "10.7710/2162-3309.1252",
  "10.7710/2162-3309.1252",
  "10.7710/2162-3309.1252"
)

get_bib = function(){
  
  doi = doi_df %>% pull(doi)
  
  x = 
    cr_works(dois = doi) %>%
    purrr::pluck("data") %>% dplyr::select(author, published.online, title)
  
  x2 = x[[1]]
  x2[1,"family"]
  
  x %>% 
    rowwise(author = as.data.frame(x$author)[1,"family"]) 
  
  date = x$published.online
  
}

}