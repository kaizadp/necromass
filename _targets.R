# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline # nolint

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes) # Load other packages as needed. # nolint

# Set target options:
tar_option_set(
  packages = c("tibble"), # packages that your targets need to run
  format = "rds" # default storage format
  # Set other options as needed.
)


# Run the R scripts in the R/ folder with your custom functions:
source("2-code/0-packages.R")
source("2-code/1-processing.R")
#source("2-code/2-exploration.R")

# Replace the target list below with your own:
list(
  ## V1.0.0 -- 2024 DATA
  # load raw database
  tar_target(V1_db_gsheets_data, "1-data/necromass_database_RAW - 2024.csv", format = "file"),
  tar_target(V1_db_gsheets, read.csv(V1_db_gsheets_data, na = c("", "N/A"))),
  # process and clean data
  tar_target(V1_db_processed, clean_db(V1_db_gsheets)),
  tar_target(V1_db_processed_data, V1_db_processed$DB_WITH_NUMBERS),
  tar_target(V1_db_processed_studies, V1_db_processed$STUDIES_FULL),
  
  #  # export
  #  tar_target(V1_export, {
  #    write.csv(V1_db_processed_data, "3-database/database_data.csv", row.names = FALSE, na = "")
  #    write.csv(V1_db_processed_studies, "3-database/database_studies.csv", row.names = FALSE, na = "")
  #  }, 
  #  format = "file"),
  
  ## V2.0.0 -- 2026 DATA
  # load raw database
  tar_target(V2_db_gsheets_data, "1-data/necromass_database_RAW - 2026.csv", format = "file"),
  tar_target(V2_db_gsheets, read.csv(V2_db_gsheets_data, na = c("", "N/A"))),
  # process and clean data
  tar_target(V2_db_processed, clean_db_2026(V2_db_gsheets, V1_db_processed_data, V1_db_processed_studies)),
  tar_target(V2_db_processed_data, V2_db_processed$DB_WITH_NUMBERS),
  tar_target(V2_db_processed_studies, V2_db_processed$STUDIES_FULL),
  
  # export
  tar_target(V2_export, {
    write.csv(V2_db_processed_data, "3-database/database_data - 2026.csv", row.names = FALSE, na = "")
    write.csv(V2_db_processed_studies, "3-database/database_studies - 2026.csv", row.names = FALSE, na = "")
  }, 
  format = "file"),
  
  ## combined for V2
  tar_target(V2_DB_DATA_COMBINED, bind_rows(V1_db_processed_data %>% mutate_all(as.character), V2_db_processed_data%>% mutate_all(as.character))),
  tar_target(V2_DB_STUDIES_COMBINED, bind_rows(V1_db_processed_studies %>% mutate_all(as.character), V2_db_processed_studies %>% mutate_all(as.character))),
  
  # export
  tar_target(V2_combined_export, {
    write.csv(V2_DB_DATA_COMBINED, "3-database/V2_database_data.csv", row.names = FALSE, na = "")
    write.csv(V2_DB_STUDIES_COMBINED, "3-database/V2_database_studies.csv", row.names = FALSE, na = "")
  }, 
  format = "file")
  
  # reports
  #tar_render(report_exploratory, path = "4-reports/a-report-exploratory.Rmd")
)
