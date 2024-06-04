#!/usr/bin/env Rscript

# This is a helper script to run the pipeline.
# Choose how to execute the pipeline below.
# See https://books.ropensci.org/targets/hpc.html
# to learn about your options.


## Download the raw data from Google Drive
## This is commented out because it is not needed for each run
## Run these lines of code only if you need to download an updated version from Google Drive
# db_gsheets = read_sheet("1nQc80bapNh3LI50Fdn-ybvKbSyyMs2jpc5SWMJ3Hy4c", 
#                        sheet = "database", col_types = "c")
# db_gsheets %>% write.csv("1-data/RAW-db_gsheets.csv", row.names = FALSE, na = "")

targets::tar_make()
targets::tar_load_everything()
# targets::tar_make_clustermq(workers = 2) # nolint
# targets::tar_make_future(workers = 2) # nolint
