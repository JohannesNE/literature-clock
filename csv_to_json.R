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
                     'nsfw_overwrite')

# Load profanity patterns
source("profanity_patterns.R")

litclock <- mutate(litclock, 
                   auto_nsfw = str_detect(quote, regex(paste0("\\b", profanity_patterns, "\\b", collapse = "|"), ignore_case = TRUE)),
                   nsfw = nsfw_overwrite == "nsfw" | (auto_nsfw & nsfw_overwrite != "sfw"),
                   sfw = ifelse(!nsfw, "yes", "no"))                     

# Use markdown::smartypants to convert ASCII punctuation to smart punctuations
litclock <- mutate(litclock, 
                    quote = purrr::map_chr(litclock$quote, ~markdown::smartypants(text = .x)),
                    quote_time = purrr::map_chr(litclock$quote_time, ~markdown::smartypants(text = .x))
)

litclock <- mutate(litclock, split_str = str_split(quote, regex(paste0('(?<!\\w)', quote_time, '(?!\\w)'), ignore_case = TRUE), n = 2),
                   quote_time_case = str_extract(quote, regex(paste0('(?<!\\w)', quote_time, '(?!\\w)'), ignore_case = TRUE)),
                   quote_first = unlist(map(split_str, `[`, 1)),
                   quote_last = unlist(map(split_str, `[`, 2)))


quote_errors <- filter(litclock, is.na(quote_time_case) | is.na(quote_first) | is.na(quote_first))
if(nrow(quote_errors) > 0) {
  print(quote_errors)
  stop("The above quotes contain parsing errors!")
}

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

