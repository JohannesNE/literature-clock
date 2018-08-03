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
                     'author')
litclock$quote_time[598] <- 'around ten'

litclock <- mutate(litclock, split_str = str_split(quote, regex(quote_time, ignore_case = TRUE), n = 2),
                   quote_time_case = str_extract(quote, regex(quote_time, ignore_case = TRUE)),
                   quote_first = unlist(map(split_str, `[`, 1)),
                   quote_last = unlist(map(split_str, `[`, 2)))
  

litclock_list <- litclock %>% 
  select(time, quote_first, quote_time_case, quote_last, title, author) %>% 
  split(litclock$time)

cat(toJSON(litclock_list, pretty = TRUE), file = "litclock_annotated.json")
