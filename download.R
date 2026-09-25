library(tidyverse)
library(lubridate)

# Cutoff date for 10 years ago from today
start_date <- Sys.Date() - years(10)

# Column names corresponding to Meteostat hourly data format
cols <- c("date", "hour", "temp", "dwpt", "rhum", "prcp", "snow", 
          "wdir", "wspd", "wpgt", "pres", "tsun", "coco")

# Helper function to download and clean hourly weather for a station
download_hourly <- \(station_id, city_name) {
  url <- paste0("https://bulk.meteostat.net/v2/hourly/", station_id, ".csv.gz")
  
  read_csv(url, col_names = cols, col_types = cols_only(
    date = col_date(),
    hour = col_integer(),
    temp = col_double(),
    prcp = col_double()
  ), show_col_types = FALSE) |>
    filter(date >= start_date) |>
    mutate(
      city = city_name,
      date = ymd_h(paste(date, hour)),
      temp_c = temp,
      temp_f = (temp * 9 / 5) + 32,
      rainfall_mm = replace_na(prcp, 0)
    ) |>
    filter(!is.na(temp_f)) |>
    select(city, date, temp_c, temp_f, rainfall_mm)
}

# Download hourly data for Sarasota (KSRQ0) and Ulaanbaatar (44292)
sarasota <- download_hourly("KSRQ0", "Sarasota")
mongolia <- download_hourly("44292", "Ulaanbaatar")

# Combine both locations into one dataset
weather <- bind_rows(sarasota, mongolia)

# Save to CSV
write_csv(weather, "hourly_temperatures.csv")
message("Saved hourly temperature data to hourly_temperatures.csv")
