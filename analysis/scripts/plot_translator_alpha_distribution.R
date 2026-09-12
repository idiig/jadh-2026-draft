#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(rstatix)
})

script_path <- commandArgs(trailingOnly = FALSE) |>
  str_subset("^--file=") |>
  str_remove("^--file=")

repo_root <- if (length(script_path) == 0) {
  getwd()
} else {
  normalizePath(file.path(dirname(script_path), "..", ".."))
}

data_path <- file.path(repo_root, "analysis", "data", "poem_alpha_1_1000.csv")
figure_dir <- file.path(repo_root, "analysis", "figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

alpha_data <- readr::read_csv(data_path, show_col_types = FALSE) |>
  mutate(alpha = as.numeric(alpha)) |>
  filter(!is.na(alpha))

alpha_stats <- alpha_data |>
  get_summary_stats(alpha, type = "mean_sd")

x_limits <- range(alpha_data$alpha, na.rm = TRUE)
x_padding <- diff(x_limits) * 0.05
if (x_padding == 0) {
  x_padding <- 0.05
}
x_limits <- c(x_limits[1] - x_padding, x_limits[2] + x_padding)
x_breaks <- pretty(x_limits, n = 5)

case_examples <- tibble::tribble(
  ~target_alpha, ~poem_id, ~alpha, ~poem_lines, ~label_y,
  0.2, 382, 0.194444, "かへる山\nなにそはありて [Katagiri, Komachiya, Okumura, Ozawa, Takeoka]\nあるかひも [Kyusojin]\nきてもとまらぬ\n名にこそありけれ", 7.1,
  0.4, 983, 0.415205, "わかいほは\n宮このたつみ [Katagiri, Takeoka]\nしかそすむ [Katagiri, Kojima/Arai, Komachiya, Kubota, Matsuda, Okumura, Ozawa, Takeoka]\nよをうち山と\n人はいふなり", 5.45,
  0.6, 923, 0.593979, "ぬきみたる\n人こそあるらし [Katagiri, Kojima/Arai, Komachiya, Kyusojin, Matsuda, Okumura, Ozawa, Takeoka]\n白玉の\nまなくもちるか [Katagiri, Kojima/Arai, Kubota, Kyusojin, Matsuda, Okumura, Ozawa, Takeoka]\nそてのせはきに", 3.8,
  0.8, 77, 0.805068, "いさゝくら [Katagiri, Ozawa]\n我もちり南 [Kaneko, Katagiri, Kojima/Arai, Komachiya, Kubota, Kyusojin, Matsuda, Okumura, Ozawa, Takeoka, morph]\nひとさかり\n有なは人に\nうきめ見え南", 2.15,
  1.0, 1, 1.000000, "年の内に\n春はきにけり [Kaneko, Katagiri, Kojima/Arai, Komachiya, Kubota, Kyusojin, Matsuda, Okumura, Ozawa, Takeoka, morph]\nひとゝせを\nこそとやいはむ [morph]\nことしとやいはむ", 0.7
) |>
  mutate(
    case_label = paste0(
      "alpha=", formatC(alpha, format = "f", digits = 3),
      "  no.", poem_id,
      "\n", poem_lines
    )
  )

density_data <- density(
  alpha_data$alpha,
  adjust = 2/3,
  from = x_limits[1],
  to = x_limits[2],
  n = 512
)

fig_size <- 5.6
fill_color <- "#0072B2"
ylim_max <- max(c(density_data$y, case_examples$label_y)) * 1.08

svg(
  file.path(figure_dir, "translator_alpha_distribution.svg"),
  width = fig_size,
  height = fig_size,
  family = "Hiragino Mincho ProN",
  bg = "transparent"
)
par(mar = c(2.8, 3.2, 1.0, 1.0), mgp = c(1.8, 0.55, 0), cex = 1.2, xpd = NA)

plot.new()
plot.window(xlim = x_limits, ylim = c(0, ylim_max))

polygon(
  c(density_data$x, rev(density_data$x)),
  c(density_data$y, rep(0, length(density_data$y))),
  col = adjustcolor(fill_color, alpha.f = 0.75),
  border = NA
)

axis(1, at = x_breaks, col = "black", col.axis = "black")
title(xlab = expression("Krippendorff's"~alpha~"among ten translators"))

text(
  x = 0.8,
  y = ylim_max * 0.96,
  labels = expression(alpha["10 translators"]),
  col = fill_color,
  adj = c(1, 1)
)

text(
  x = 0.8,
  y = ylim_max * 0.91,
  labels = bquote(
    mean == .(formatC(alpha_stats$mean, format = "f", digits = 3)) *
      ";" ~ N == .(alpha_stats$n) *
      ";" ~ std. == .(formatC(alpha_stats$sd, format = "f", digits = 3))
  ),
  col = "black",
  adj = c(1, 1),
  cex = 0.95
)

text(
  x = x_limits[1],
  y = case_examples$label_y,
  labels = case_examples$case_label,
  adj = c(0, 0.5),
  cex = 0.38,
  col = "black"
)

dev.off()

message("Wrote translator alpha density figure to ", figure_dir)
