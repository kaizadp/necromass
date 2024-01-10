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
    mutate(Latitude = Latitude_corrected,
           Longitude = Longitude_corrected) %>% 
    
    dplyr::select(-c("latitude_dec", "latitude_deg", "lat",
                     "longitude_dec", "longitude_deg", "lon",
                     "Latitude_corrected", "Longitude_corrected")) 
  
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
  # these rownumbers will be carried throughout the rest of the processing script,
  # used to connect separate pieces later
  db_rows <- 
    db_gsheets %>% 
    rownames_to_column("rownumber") 

  # now split the big dataframe into smaller pieces to process separately ----   
  # 1. metadata (includes site info and sample info)
  db_metadata <- 
    db_rows %>% 
    dplyr::select(
      rownumber, sample, notes,
      treatment, treatment_level,
      latitude, longitude, lat_lon_notes, elevation_m, lyrtop_cm, lyrbot_cm, horizon,
      soil_type, ecosystem, wetland_type, plant_species, 
      year_sampled,
      fraction_scheme, aggregate_size
    ) %>% 
    force()
  
  # 1b. bibliography info (author, doi, etc.)
  db_biblio <- 
    db_rows %>% 
    dplyr::select(
      rownumber, author, author_doi) %>% 
    force()
  
  # 2. soil (includes TC, TN, pH, etc.)
  db_soil <- 
    db_rows %>% 
    dplyr::select(
      rownumber,
      contains("biomass"),
      soc, soil_C, soil_N,
      pH, pH_method, clay, silt, sand
    ) %>% 
    force()
  
  # 3. necromass (includes AS and necromass)
  db_necromass = 
    db_rows %>% 
    dplyr::select(rownumber, gluN, murA, galN, manN, contains("necromass")) %>% 
    mutate_all(as.numeric) %>% 
    column_to_rownames("rownumber") %>% 
    janitor::remove_empty("rows") %>% 
    rownames_to_column("rownumber")
  
  #
  # PROCESS METADATA ----
  db_metadata_processed <- 
    db_metadata %>% 
    rename(Latitude = latitude, Longitude = longitude) %>% 
    clean_lat_lon() %>% 
    assign_climate_biome() %>% 
    mutate(ecosystem = tolower(ecosystem)) %>% 
    dplyr::select(rownumber, sample, notes,
                  Latitude, Longitude, lat_lon_notes, elevation_m, 
                  MAT, MAP, ClimateTypes, everything())
  
  ## PROCESSING AND CALCULATING NECROMASS COLUMNS ----
  ## we have AS data and also some data as necromass.
  ## pull these columns
  ## -- where we have AS data, convert to fungal/bacterial necromass
  ## -- where no AS data but FNC, BNC, use those values
  ## -- then FNC + BNC = microbial necromass C
    
  db_necromass2 = 
    db_necromass %>% 
    mutate(AS_data = (!is.na(gluN|galN|murA|manN)),
           necro_data = !is.na(bacterial_necromass_C|fungal_necromass_C))
  
  db_necromass_as = 
    db_necromass2 %>% 
    filter(AS_data) %>% 
## ^need to calculate FNC and BNC and MNC from these
## units are mg/kg
    mutate(bacterial_necromass_C = murA * 45,
           fungal_necromass_C = ((gluN/179.17) - (2 * murA/251.23)) * 179.17 * 9,
           microbial_necromass_C = bacterial_necromass_C + fungal_necromass_C)
    
    
  db_necromass_fnc_bnc = 
    db_necromass2 %>% 
    filter(necro_data & !AS_data) %>% 
    mutate(microbial_necromass_C = bacterial_necromass_C + fungal_necromass_C)
## ^need to back-calculate gluN and murA?? -- probably not  
  
  db_necromass_mnc = 
    db_necromass2 %>% 
    filter(!is.na(microbial_necromass_C) & !AS_data & !necro_data)
## ^ leave untouched
  
  db_necromass_CALCULATED = 
    bind_rows(db_necromass_as, db_necromass_fnc_bnc, db_necromass_mnc)

  
  DB_PROCESSED = 
    db_metadata_processed %>% 
    right_join(db_necromass_CALCULATED) %>% 
    left_join(db_soil)

  DB_PROCESSED
  }

