# literature CSV to JSON
library(readr)
library(tidyverse)
library(stringr)
library(jsonlite)

litclock <- read_delim("litclock_annotated.csv",
"|", escape_double = TRUE, col_names = FALSE,
col_types = cols(X1 = col_character()),
trim_ws = TRUE)


names(litclock) <- c('time',
                     'quote_time',
                     'quote',
                     'title',
                     'author',
                     'sfw')

# Use markdown::smartypants to convert ASCII punctuation to smart punctuations
litclock$quote <- purrr::map_chr(litclock$quote, ~markdown::smartypants(text = .x))

litclock <- mutate(litclock, split_str = str_split(quote, regex(paste0('(?<!\\w)', quote_time, '(?!\\w)'), ignore_case = TRUE), n = 2),
                   quote_time_case = str_extract(quote, regex(paste0('(?<!\\w)', quote_time, '(?!\\w)'), ignore_case = TRUE)),
                   quote_first = unlist(map(split_str, `[`, 1)),
                   quote_last = unlist(map(split_str, `[`, 2)))

# To copy text to times without quotes the data is nested.
#all_timestamps <- tibble(time = format(seq(as.POSIXct("2013-01-01 00:00:00", tz="GMT"),
#                             length.out=1440, by='1 min'), '%H:%M'))

#litclock <- litclock %>%
  #nest(data = -time) %>%
  #right_join(all_timestamps, by = "time") %>%
  #arrange(time) %>%
  #fill(data) %>%
  #unnest(cols = data)

# Create list by timestamp and save to individual files
litclock_list <- litclock %>%
  select(time, quote_first, quote_time_case, quote_last, title, author, sfw) %>%
  split(litclock$time)

# cat(toJSON(litclock_list, pretty = TRUE), file = "litclock_annotated.json")



# save individual files
lit_times_path <- 'docs/times/'
save_json <- function(df) {
  cat(toJSON(df, pretty = TRUE), file = paste0(lit_times_path, sub(':', '_', df$time[1]), ".json"))
}

lapply(litclock_list, save_json)
