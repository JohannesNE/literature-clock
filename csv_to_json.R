# literature CSV to JSON
library(readr)
library(dplyr)
library(purrr)
library(stringr)
library(jsonlite)

n_csv_rows <- read_lines("litclock_annotated.csv") |> length()

litclock <- read_delim("litclock_annotated.csv",
"|", col_names = FALSE,
quote = "",
col_types = cols(X1 = col_character()),
trim_ws = TRUE)

names(litclock) <- c('time',
                     'quote_time',
                     'quote',
                     'title',
                     'author',
                     'nsfw_overwrite')

if(n_csv_rows != nrow(litclock)) {
  warning("There is not one quote per row in the csv!\nThese rows may be problematic:")
  filter(litclock, str_detect(quote, "\\|")) 
}

# Load profanity patterns
source("profanity_patterns.R")

litclock <- mutate(litclock, 
                   auto_nsfw = str_detect(quote, regex(paste0("\\b", profanity_patterns, "\\b", collapse = "|"), ignore_case = TRUE)),
                   nsfw = nsfw_overwrite == "nsfw" | (auto_nsfw & nsfw_overwrite != "sfw"),
                   sfw = ifelse(!nsfw, "yes", "no"))                     

# Use markdown::mark to convert ASCII punctuation to smart punctuations
# TODO: Find better way to remove trailing newline
litclock <- mutate(litclock, 
                    quote = purrr::map_chr(litclock$quote, ~markdown::mark(text = .x, options = "smartypants") |> str_sub(start = 4, end = -6) ),
                    quote_time = purrr::map_chr(litclock$quote_time, ~markdown::mark(text = .x, options = "smartypants") |> str_sub(start = 4, end = -6) )
)

# \\Q and \\E make the text in between literal
litclock <- mutate(litclock, split_str = str_split(quote, regex(paste0('(?<!\\w)\\Q', quote_time, '\\E(?!\\w)'), ignore_case = TRUE), n = 2),
                   quote_time_case = str_extract(quote, regex(paste0('(?<!\\w)\\Q', quote_time, '\\E(?!\\w)'), ignore_case = TRUE)),
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

unlink(lit_times_path, recursive = TRUE)
dir.create(lit_times_path)
lapply(litclock_list, save_json)

