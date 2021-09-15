suppressMessages(library(dplyr))

temp_data_set <-
  climate::meteo_imgw_daily(year = 2001:2020)

# temp_data_set %>%
#   mutate(date = lubridate::make_date(yy, mm, day)) %>%
#   group_by(station) %>%
#   summarise(max_date = max(date),
#             min_date = min(date), n = n())

weather_pl <-
  temp_data_set %>%
  filter(station %in% c("SUWAŁKI", "TARNÓW")) %>%
  mutate(date = lubridate::make_date(yy, mm, day)) %>%
  select(-rank, -id, -yy, -mm, -day) %>%
  select(station, date, starts_with("tm"), starts_with("rr"), starts_with("press"))

weather_pl <-
  weather_pl %>%
  mutate(station = case_when(
    station == "TARNÓW"  ~ "TRN",
    station == "SUWAŁKI" ~ "SWK"
  ))

save(weather_pl, file = here::here("data/weather_pl.rda"))
