#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
})

script_path <- commandArgs(trailingOnly = FALSE) |>
  str_subset("^--file=") |>
  str_remove("^--file=")

repo_root <- if (length(script_path) == 0) {
  getwd()
} else {
  normalizePath(file.path(dirname(script_path), "..", ".."))
}

comparison_path <- file.path(repo_root, "analysis", "data", "morph_translator_comparison_1_1000.csv")
poem_agreement_path <- file.path(repo_root, "analysis", "data", "poem_11_judgement_agreement_1_1000.csv")
cumulative_path <- file.path(repo_root, "analysis", "data", "cumulative_11_judgement_agreement_1_1000.csv")
figure_dir <- file.path(repo_root, "analysis", "figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

parse_positions <- function(value) {
  if (is.na(value) || stringr::str_trim(value) == "") {
    return(integer())
  }
  stringr::str_split(stringr::str_trim(value), "\\s+")[[1]] |>
    as.integer()
}

position_counts <- function(translator_positions, morph_positions) {
  counts <- rep(0L, 5)
  for (value in translator_positions) {
    positions <- parse_positions(value)
    if (length(positions) == 0) {
      counts[5] <- counts[5] + 1L
    } else {
      for (position in positions) {
        if (!is.na(position) && position >= 1 && position <= 4) {
          counts[position] <- counts[position] + 1L
        }
      }
    }
  }

  morph <- parse_positions(morph_positions[[1]])
  if (length(morph) == 0) {
    counts[5] <- counts[5] + 1L
  } else {
    for (position in morph) {
      if (!is.na(position) && position >= 1 && position <= 4) {
        counts[position] <- counts[position] + 1L
      }
    }
  }
  counts
}

poem_agreement <- readr::read_csv(
  comparison_path,
  col_types = readr::cols(
    .default = readr::col_guess(),
    translator_positions = readr::col_character(),
    morph_positions = readr::col_character()
  )
) |>
  filter(morph_level == "high") |>
  group_by(poem_id) |>
  summarise(
    counts = list(position_counts(translator_positions, morph_positions)),
    .groups = "drop"
  ) |>
  mutate(
    count_1 = map_int(counts, 1),
    count_2 = map_int(counts, 2),
    count_3 = map_int(counts, 3),
    count_4 = map_int(counts, 4),
    count_5 = map_int(counts, 5),
    max_agreement = pmax(count_1, count_2, count_3, count_4, count_5),
    max_position = pmap_int(
      list(count_1, count_2, count_3, count_4, count_5),
      function(...) which.max(c(...))
    )
  ) |>
  select(poem_id, count_1, count_2, count_3, count_4, count_5, max_agreement, max_position)

readr::write_csv(poem_agreement, poem_agreement_path)

agreement <- tibble(threshold = 6:11) |>
  mutate(
    label = paste0(">=", threshold),
    poems = map_int(threshold, ~ sum(poem_agreement$max_agreement >= .x)),
    total = nrow(poem_agreement),
    percent = poems / total
  )

readr::write_csv(agreement, cumulative_path)

agreement <- agreement |>
  mutate(
    threshold_label = paste0("≥", threshold),
    percent = as.numeric(percent),
    percent_label = scales::percent(percent, accuracy = 0.1)
  )

total_poems <- unique(agreement$total)[[1]]
ylim_max <- max(agreement$poems) * 1.16
y_ticks <- pretty(c(0, max(agreement$poems)))
p_ticks <- y_ticks / total_poems
bp <- barplot(agreement$poems, plot = FALSE, space = 0.3)
axis_bar_gap <- 0.7
xlim_range <- c(min(bp) - axis_bar_gap, max(bp) + axis_bar_gap)

phi <- (1 + sqrt(5)) / 2
fig_size <- 5.6
svg(
  file.path(figure_dir, "cumulative_11_judgement_agreement.svg"),
  width = fig_size,
  height = fig_size,
  family = "Hiragino Mincho ProN",
  bg = "transparent"
)
par(mar = c(2.8, 3.8, 1.0, 5.0), mgp = c(1.8, 0.55, 0), cex = 1.2, xpd = NA)

plot.new()
plot.window(xlim = xlim_range, ylim = c(0, ylim_max))

bp <- barplot(
  agreement$poems,
  names.arg = agreement$threshold_label,
  col = "#0072B2",
  border = NA,
  ylim = c(0, ylim_max),
  space = 0.3,
  xlab = "",
  ylab = "",
  add = TRUE,
  axes = FALSE,
  xlim = xlim_range
)

axis(1, at = bp, labels = agreement$threshold_label)
axis(2, at = y_ticks)
title(
  xlab = "Minimum number of agreeing judgements",
  ylab = "Number of poems"
)

text(
  bp,
  agreement$poems + max(agreement$poems) * 0.035,
  labels = agreement$poems,
  cex = 0.95,
  col = "black",
  xpd = NA
)
text(
  bp,
  agreement$poems + max(agreement$poems) * 0.075,
  labels = agreement$percent_label,
  cex = 0.95,
  col = "#D55E00",
  xpd = NA
)

axis(
  4,
  line = 0,
  at = y_ticks,
  labels = scales::percent(p_ticks, accuracy = 1),
  col = "#D55E00",
  col.axis = "#D55E00"
)
mtext("Percentage", side = 4, line = 1.8, col = "#D55E00", cex = 1.2)

dev.off()

message("Wrote cumulative agreement figure to ", figure_dir)
