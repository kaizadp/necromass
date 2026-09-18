library(tidyverse)
library(janitor)   # install.packages("janitor") if needed

# ---- 1. Load both files -------------------------------------------------
data_path    <- "3-database/V2_database_data.csv"
studies_path <- "3-database/V2_database_studies.csv"

# Studies file has a header row
studies <- read_csv(studies_path, show_col_types = FALSE) %>%
  clean_names()

# Data file: read as character first to inspect, then let readr guess types
# If the first row is actually a header, read_csv will use it; otherwise set col_names
data_raw <- read_csv(data_path, show_col_types = FALSE, guess_max = 100000)

# ---- 2. Basic shape diagnostics ----------------------------------------
diagnose_shape <- function(df, name) {
  cat("\n==== ", name, " ====\n")
  cat("Rows:", nrow(df), " Cols:", ncol(df), "\n")
  cat("Column names:\n")
  print(names(df))
}
diagnose_shape(data_raw, "V2_database_data.csv")
diagnose_shape(studies, "V2_database_studies.csv")

# ---- 3. Missing-value report per column --------------------------------
missing_report <- function(df) {
  df %>%
    summarise(across(everything(), ~ sum(is.na(.) | . == ""))) %>%
    pivot_longer(everything(), names_to = "column", values_to = "n_missing") %>%
    mutate(pct_missing = round(100 * n_missing / nrow(df), 1)) %>%
    arrange(desc(n_missing))
}

cat("\n---- Missing values: DATA ----\n")
print(missing_report(data_raw), n = Inf)

cat("\n---- Missing values: STUDIES ----\n")
print(missing_report(studies), n = Inf)

# ---- 4. Duplicate checks -----------------------------------------------
cat("\n---- Fully duplicated rows (data) ----\n")
cat(sum(duplicated(data_raw)), "\n")

# Duplicate study numbers in the studies table (should be unique keys)
cat("\n---- Duplicate SNDB_study_number in studies ----\n")
studies %>% count(sndb_study_number) %>% filter(n > 1) %>% print(n = Inf)

# ---- 5. Numeric summaries & range/validity checks ----------------------
# Adjust these column names to match your actual headers
num_summary <- data_raw %>%
  select(where(is.numeric)) %>%
  summarise(across(everything(),
                   list(min = ~min(., na.rm = TRUE),
                        max = ~max(., na.rm = TRUE),
                        mean = ~mean(., na.rm = TRUE),
                        n_na = ~sum(is.na(.))),
                   .names = "{.col}__{.fn}")) %>%
  pivot_longer(everything(),
               names_to = c("column", "stat"),
               names_sep = "__") %>%
  pivot_wider(names_from = stat, values_from = value)
cat("\n---- Numeric summary (data) ----\n")
print(num_summary, n = Inf)

# Plausibility flags — rename to your true column names
validity_flags <- data_raw %>%
  mutate(row_id = row_number()) %>%
  summarise(
    bad_latitude  = sum(latitude  < -90  | latitude  > 90,  na.rm = TRUE),
    bad_longitude = sum(longitude < -180 | longitude > 180, na.rm = TRUE),
    bad_pH        = sum(pH < 0 | pH > 14, na.rm = TRUE),
    neg_SOC       = sum(SOC < 0, na.rm = TRUE)
  )
cat("\n---- Validity flags (data) ----\n")
print(validity_flags)

# ---- 6. Referential integrity between the two files --------------------
# Every study number in the data should exist in the studies table
data_studies    <- data_raw %>% distinct(SNDB_study_number) %>% pull()
studies_present <- studies %>% pull(sndb_study_number)

orphan_studies <- setdiff(as.character(data_studies),
                          as.character(studies_present))
cat("\n---- Study numbers in DATA but missing from STUDIES ----\n")
print(orphan_studies)

unused_studies <- setdiff(as.character(studies_present),
                          as.character(data_studies))
cat("\n---- Study numbers in STUDIES but never used in DATA ----\n")
print(unused_studies)
