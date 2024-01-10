
db_gsheets = read_sheet("1nQc80bapNh3LI50Fdn-ybvKbSyyMs2jpc5SWMJ3Hy4c", 
                        sheet = "database", col_types = "c")
db_gsheets_cols = 
  db_gsheets[3, ] %>% 
  pivot_longer(cols = everything()) %>% 
  fill(value)


db_processed = clean_db(db_gsheets)


# checking lat-lon
db_lat_lon <- 
  db_gsheets %>%
  dplyr::select(latitude, longitude, lat_lon_notes) %>% 
  filter(!is.na(latitude)) %>% 
 # mutate_at(vars(c(latitude, longitude)), as.numeric) %>% 
  mutate(latitude2 = latitude,
         longitude2 = longitude) %>% 
  rename(Latitude = latitude, Longitude = longitude) %>% 
  clean_lat_lon() 


db_lat_lon_setup <- 
  db_gsheets %>%
  dplyr::select(latitude, longitude, lat_lon_notes) %>% 
  filter(!is.na(latitude)) %>% 
  # mutate_at(vars(c(latitude, longitude)), as.numeric) %>% 
  mutate(latitude2 = latitude,
         longitude2 = longitude) %>% 
  rename(Latitude = latitude, Longitude = longitude)



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