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
  # load raw database
  tar_target(db_gsheets_data, "1-data/RAW-db_gsheets.csv", format = "file"),
  tar_target(db_gsheets, read.csv(db_gsheets_data)),
  # process and clean data
  tar_target(db_processed, clean_db(db_gsheets)),
  tar_target(db_processed_data, db_processed$DB_WITH_NUMBERS),
  tar_target(db_processed_studies, db_processed$STUDIES_FULL),
  
 # export
 tar_target(export, {
   write.csv(db_processed_data, "3-database/database_data.csv", row.names = FALSE, na = "")
   write.csv(db_processed_studies, "3-database/database_studies.csv", row.names = FALSE, na = "")
 }, 
 format = "file")
  
  # reports
  #tar_render(report_exploratory, path = "4-reports/a-report-exploratory.Rmd")
)
