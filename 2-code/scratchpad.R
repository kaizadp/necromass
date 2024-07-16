
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


library(rcrossref)
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
    "https://doi.org/10.1111/gcb.16676",
    "https://doi.org/10.1016/j.agee.2020.106816"
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

## bibliography ----

install.packages("RefManageR")
library(RefManageR)


dat <- do.call(bind_rows, lapply(doi_df$doi, function(x){
  
  x = 
    GetBibEntryWithDOI(x) %>% 
    as.data.frame() %>% 
    rownames_to_column("study") %>% 
    dplyr::select(study, doi, title, author, journal, year)
  
  
}))




db_processed_data %>% count(gluN)

x = db_processed_data %>% 
summarise_all(funs(sum(!is.na(.)))) %>% 
  pivot_longer(everything())


db_processed_data %>% skimr::skim()
x = str(db_processed_data)
