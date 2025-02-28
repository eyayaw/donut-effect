#####CBD from Holian#####

library(tigris)
library(tidyverse)
library(readr)
library(sp)
library(rgdal)

df <- readxl::read_excel('./data/external_data/holian_cbd_geocodes.xlsx', 
                         sheet = 'copy_of_merged_data2') %>%
  mutate(cbd_lat = ifelse(!is.na(Cen82lat), Cen82lat, CityHallLat),
         cbd_lon = ifelse(!is.na(Cen82lon), Cen82lon, CityHallLon)) %>%
  filter(!is.na(cbd_lat) & !is.na(cbd_lon)) %>%
  separate(CBSA_name, c("MsaName", "end"), ', ', remove = FALSE) %>% 
  mutate(MetroShort = sub("-.*", "", MsaName),
        MetroState = sub("-.*", "", end),
        MetroState = sub(" .*", "", MetroState),
        MetroShort = paste(MetroShort, MetroState, sep = ', ')) %>%
  select(MetroShort, cbd_lon, cbd_lat)
  

###merge with zipcodes and get distance from CBD
#https://www.census.gov/geographies/reference-files/time-series/geo/gazetteer-files.html

latlonzip <- read_tsv('./data/external_data/zcta_gaz.txt') %>%
  select(GEOID, INTPTLAT, INTPTLONG) %>%
  rename(lon = INTPTLONG, lat = INTPTLAT, zip = GEOID) %>%
  mutate(zip = as.integer(zip))

##bring in other zipcode chars
zip_chars <- read_csv('./data/zip_all_chars.csv')

##merge all together
zip_all_chars <- zip_chars %>% left_join(latlonzip, by = 'zip') %>% 
  left_join(df, by = 'MetroShort')

#calculate distances
#install.packages('geosphere')
library(geosphere)
zip_all_chars <- zip_all_chars %>% rowwise() %>%
  mutate(dist_to_cbd = distm(c(lon, lat), c(cbd_lon, cbd_lat), 
                      fun = distHaversine))

write_csv(zip_all_chars, './data/zip_all_chars_cbd.csv')

