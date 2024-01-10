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
  # import database from google drive
#  tar_target(db_gsheets, read_sheet("1nQc80bapNh3LI50Fdn-ybvKbSyyMs2jpc5SWMJ3Hy4c", 
#                                    sheet = "database", col_types = "c")),
  
  # process and clean data
  tar_target(db_processed, clean_db(db_gsheets)),
  
  # export
  tar_target(export, {
    write.csv(db_processed, "3-database/database_data.csv", row.names = FALSE)
    #write.csv(db_biblio, "3-databased/database_studies.csv", row.names = FALSE)
  }, format = "file"),
  
  # reports
  tar_render(report_exploratory, path = "4-reports/a-report-exploratory.Rmd")
)
