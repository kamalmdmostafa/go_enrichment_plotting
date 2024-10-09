# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(readxl)
library(writexl)
library(extrafont)

# Load Times New Roman font
loadfonts(device = "win")  # Use "mac" instead of "win" if you're on a Mac

# Function to read data and calculate Enrichment Score
calculate_enrichment_score <- function(file_path) {
  data <- read_excel(file_path)
  
  required_columns <- c("Cluster", "Description", "GeneRatio", "BgRatio", "p.adjust")
  missing_columns <- setdiff(required_columns, colnames(data))
  
  if (length(missing_columns) > 0) {
    stop(paste("Missing required columns:", paste(missing_columns, collapse = ", ")))
  }
  
  data <- data %>%
    mutate(
      GeneRatio_k = as.numeric(sapply(strsplit(GeneRatio, "/"), `[`, 1)),
      GeneRatio_n = as.numeric(sapply(strsplit(GeneRatio, "/"), `[`, 2)),
      BgRatio_K = as.numeric(sapply(strsplit(BgRatio, "/"), `[`, 1)),
      BgRatio_N = as.numeric(sapply(strsplit(BgRatio, "/"), `[`, 2)),
      GeneRatio_numeric = GeneRatio_k / GeneRatio_n,
      BgRatio_numeric = BgRatio_K / BgRatio_N,
      EnrichmentScore = GeneRatio_numeric / BgRatio_numeric
    )
  
  return(data)
}

# Function to get top n terms per cluster
get_top_n_terms <- function(data, n) {
  data %>%
    group_by(Cluster) %>%
    top_n(-n, p.adjust) %>%
    ungroup()
}

# Function to create a single plot
create_plot <- function(data, width = 4, height = 6) {
  # Truncate long descriptions
  data <- data %>%
    mutate(Description = str_trunc(Description, 45, "right"))
  
  # Preserve exact cluster order
  cluster_order <- unique(data$Cluster)
  data$Cluster <- factor(data$Cluster, levels = cluster_order)
  
  # Preserve the order of User_Defined_Category as it appears in the data
  category_order <- unique(data$User_Defined_Category)
  data$User_Defined_Category <- factor(data$User_Defined_Category, levels = category_order)
  
  # Sort within each User_Defined_Category by EnrichmentScore (high to low)
  data <- data %>%
    arrange(User_Defined_Category, desc(EnrichmentScore)) %>%
    mutate(Description = factor(Description, levels = rev(unique(Description))))
  
  plot <- ggplot(data, aes(x = Cluster, y = Description)) +
    geom_tile(aes(fill = User_Defined_Category), alpha = 0.3, width = Inf) +
    geom_point(aes(color = p.adjust, size = EnrichmentScore)) +
    scale_fill_discrete(name = "Category") +
    scale_color_gradient(low = "red", high = "blue") +
    scale_size(range = c(1, 4), name = "Enrichment Score") +
    ggtitle("GO Terms Dot Plot - BP - Simplified") +
    theme_minimal() +
    theme(
      text = element_text(family = "Times"),
      plot.title = element_text(hjust = 0.5, size = 12),
      axis.text.y = element_text(size = 7, margin = margin(r = 2), color = "black"),
      axis.text.x = element_text(angle = 45, hjust = 1, vjust = 0.5, size = 6),
      axis.title = element_text(size = 10),
      legend.text = element_text(size = 5),
      legend.title = element_text(size = 6),
      plot.margin = margin(5, 15, 5, 5, "pt"),
      panel.grid.major.y = element_line(color = "lightgrey", linewidth = 0.2),
      axis.ticks.length = unit(0, "pt"),
      panel.spacing = unit(0.05, "lines"),
      panel.spacing.x = unit(0, "lines"),
      legend.position = "right",
      legend.key.size = unit(0.5, "lines"),
      legend.box.just = "left",
      legend.justification = "left",
      legend.box.background = element_rect(fill = "white", color = NA),
      legend.background = element_rect(fill = "white", color = NA),
      legend.box = "vertical",
      legend.spacing = unit(0.1, "cm"),
      legend.margin = margin(0, 0, 0, 0)
    ) +
    guides(
      color = guide_colorbar(order = 1, title = "p.adjust"),
      size = guide_legend(order = 2, title = "Enrichment Score"),
      fill = guide_legend(order = 3, title = "Category")
    ) +
    coord_cartesian(clip = "off") +
    scale_x_discrete(expand = expansion(mult = c(0.05, 0.05))) +
    scale_y_discrete(expand = expansion(mult = c(0, 0)))
  
  return(plot)
}

# Add a new function to filter data by Enrichment Score
filter_by_enrichment_score <- function(data, cutoff) {
  data %>%
    group_by(User_Defined_Category) %>%
    filter(EnrichmentScore >= cutoff) %>%
    ungroup()
}

# Function to export data
export_data <- function(data, filename = "enrichment_data.xlsx") {
  write_xlsx(data, path = filename)
  cat("Data exported to", filename, "\n")
}

# Function to ask user whether to continue or stop
ask_to_continue <- function(step) {
  while (TRUE) {
    user_input <- tolower(readline(sprintf("Continue to %s? (Y/N): ", step)))
    if (user_input == "y") {
      return(TRUE)
    } else if (user_input == "n") {
      return(FALSE)
    } else {
      cat("Invalid input. Please enter Y or N.\n")
    }
  }
}

# Main function
main <- function(enrichment_score_cutoff = 0) {
  # CUSTOMIZE: Replace with the actual path to your Excel file
  file_path <- 'Lipid_droplet_ordered.xlsx'
  
  # Step 1: Calculate Enrichment Score
  cat("Step 1: Calculating Enrichment Score\n")
  enriched_data <- calculate_enrichment_score(file_path)
  
  # Display the first few rows and column names
  cat("\nFirst few rows of the enriched data:\n")
  print(head(enriched_data))
  cat("\nColumns in the enriched data:\n")
  print(colnames(enriched_data))
  
  if (!ask_to_continue("Step 2 (Plotting)")) {
    cat("\nAnalysis complete after Step 1.\n")
    return(enriched_data)
  }
  
  # Step 2: Create Plot
  cat("\nStep 2: Creating Plot\n")
  # Filter data for plotting if a cutoff is specified
  plot_data <- if(enrichment_score_cutoff > 0) {
    filter_by_enrichment_score(enriched_data, enrichment_score_cutoff)
  } else {
    enriched_data
  }
  
  # CUSTOMIZE: Adjust the number of top terms per cluster (default is 30)
  top_terms <- get_top_n_terms(plot_data, 30)
  plot <- create_plot(top_terms)
  
  # Display the plot
  print(plot)
  
  # Save the plot
  ggsave("GO_BP_Simplified_dotplot.pdf", plot = plot, width = 6, height = 6, limitsize = FALSE)
  cat("Plot saved as GO_BP_Simplified_dotplot.pdf\n")
  
  if (!ask_to_continue("Step 3 (Exporting Data)")) {
    cat("\nAnalysis complete after Step 2.\n")
    return(enriched_data)
  }
  
  # Step 3: Export Data
  cat("\nStep 3: Exporting Data\n")
  export_data(enriched_data)  # Export all data without filtering
  
  cat("\nAnalysis complete.\n")
  return(enriched_data)
}

# Run the main function
main(enrichment_score_cutoff = 3)