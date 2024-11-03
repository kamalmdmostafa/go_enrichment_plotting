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

# Define distinct colors for 30 categories (original vector preserved)
distinct_colors <- c(
  "#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00",
  "#FFFF33", "#A65628", "#F781BF", "#1B9E77", "#D95F02",
  "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D",
  "#00CED1", "#FF1493", "#32CD32", "#9370DB", "#8B4513",
  "#DC143C", "#00FF7F", "#4B0082", "#CD853F", "#800000",
  "#008B8B", "#9932CC", "#FFB6C1", "#556B2F", "#2F4F4F"
)

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
      EnrichmentScore = GeneRatio_numeric / BgRatio_numeric,
      p.adjust = as.numeric(p.adjust)
    )
  
  return(data)
}

# Function to get top n terms per cluster with sorting option
get_top_n_terms <- function(data, n, sort_by = "p.adjust") {
  data %>%
    group_by(Cluster) %>%
    slice_min(order_by = if(sort_by == "p.adjust") p.adjust else -EnrichmentScore, 
              n = n, with_ties = FALSE) %>%
    ungroup()
}

# Function to filter by enrichment score
filter_by_enrichment <- function(data, cutoff) {
  filtered_data <- data %>%
    filter(EnrichmentScore >= cutoff)
  
  # Print summary statistics with na.rm = TRUE
  cat("\nEnrichment Score Summary:")
  cat("\nTotal terms before filtering:", nrow(data))
  cat("\nTerms passing cutoff (ES ≥", format(cutoff, digits = 2), "):", nrow(filtered_data))
  cat("\nRange of Enrichment Scores:")
  cat("\n  Min:", format(min(data$EnrichmentScore, na.rm = TRUE), digits = 2))
  cat("\n  Max:", format(max(data$EnrichmentScore, na.rm = TRUE), digits = 2))
  cat("\n  Median:", format(median(data$EnrichmentScore, na.rm = TRUE), digits = 2), "\n")
  
  return(filtered_data)
}

# Function to create plot with category ordering options and distinct colors
create_plot <- function(data, width = 4, height = 6, category_order = "data") {
  # Truncate long descriptions
  data <- data %>%
    mutate(Description = str_trunc(Description, 45, "right"))
  
  # Preserve exact cluster order
  cluster_order <- unique(data$Cluster)
  data$Cluster <- factor(data$Cluster, levels = cluster_order)
  
  if ("User_Defined_Category" %in% colnames(data)) {
    if (category_order == "data") {
      category_order_levels <- unique(data$User_Defined_Category)
    } else {
      data_ordered <- data %>%
        group_by(User_Defined_Category) %>%
        summarise(max_score = max(EnrichmentScore, na.rm = TRUE)) %>%
        arrange(desc(max_score))
      category_order_levels <- data_ordered$User_Defined_Category
    }
    
    # Create the ordered dataset
    ordered_data <- data %>%
      group_by(User_Defined_Category) %>%
      arrange(desc(EnrichmentScore)) %>%
      ungroup() %>%
      arrange(match(User_Defined_Category, category_order_levels))
    
    description_order <- ordered_data$Description
    
    data <- data %>%
      mutate(
        User_Defined_Category = factor(User_Defined_Category, levels = category_order_levels),
        Description = factor(Description, levels = rev(unique(ordered_data$Description)))
      )
    
    tile_aes <- aes(fill = User_Defined_Category)
    
    fill_scale <- scale_fill_manual(
      name = "Category",
      values = distinct_colors[1:length(category_order_levels)],
      limits = category_order_levels
    )
  } else {
    data <- data %>%
      arrange(desc(EnrichmentScore)) %>%
      mutate(Description = factor(Description, levels = unique(Description)))
    
    tile_aes <- aes(fill = "lightblue")
    fill_scale <- scale_fill_manual(values = c("lightblue"), name = "Category")
  }
  
  plot <- ggplot(data, aes(x = Cluster, y = Description)) +
    geom_tile(tile_aes, alpha = 0.3, width = Inf) +
    geom_point(aes(color = p.adjust, size = EnrichmentScore)) +
    fill_scale +
    scale_color_gradient(low = "red", high = "blue", name = "Adjusted p-value") +
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
      fill = guide_legend(order = 3, title = "Category", ncol = 1)
    ) +
    coord_cartesian(clip = "off") +
    scale_x_discrete(expand = expansion(mult = c(0.05, 0.05))) +
    scale_y_discrete(expand = expansion(mult = c(0, 0)))
  
  return(plot)
}

# Function to export data with custom filename
export_data <- function(data, prompt = TRUE) {
  if (prompt) {
    filename <- readline("Enter filename for data export (default: enrichment_data.xlsx): ")
    if (filename == "") filename <- "enrichment_data.xlsx"
    if (!grepl("\\.xlsx$", filename)) filename <- paste0(filename, ".xlsx")
  } else {
    filename <- "enrichment_data.xlsx"
  }
  
  tryCatch({
    write_xlsx(data, path = filename)
    cat("Data exported to", filename, "\n")
  }, error = function(e) {
    cat("Error exporting data:", e$message, "\n")
  })
}

# Function to handle visualization loop with reordered menu options
handle_visualization <- function(enriched_data) {
  current_plot <- NULL
  current_filtered_data <- NULL
  current_cutoff <- NULL
  current_category_order <- "data"
  current_sort_by <- "p.adjust"  # Default sorting by p.adjust
  
  while (TRUE) {
    # Show current enrichment score range with na.rm = TRUE
    cat("\nEnrichment Score Statistics:")
    cat("\nMin:", format(min(enriched_data$EnrichmentScore, na.rm = TRUE), digits = 2))
    cat("\nMax:", format(max(enriched_data$EnrichmentScore, na.rm = TRUE), digits = 2))
    cat("\nMedian:", format(median(enriched_data$EnrichmentScore, na.rm = TRUE), digits = 2))
    
    if (!is.null(current_cutoff)) {
      cat("\nCurrent cutoff: ≥", format(current_cutoff, digits = 2))
    }
    cat("\nCurrent sorting method:", current_sort_by)
    
    cat("\n\nEnter action:")
    cat("\n1: Enter new enrichment score cutoff")
    cat("\n2: Plot in R Studio")
    cat("\n3: Change category order (data order/plot appearance order)")
    cat("\n4: Save current plot")
    cat("\n5: Export data")
    cat("\n6: Change sorting method (p.adjust/EnrichmentScore)")
    cat("\n7: Quit visualization\n")
    
    action <- readline("Choose action (1-7): ")
    
    if (action == "1") {
      #cutoff_input <- readline("Enter enrichment score cutoff (e.g., 1.5, 2, 2.5): ")
      cutoff_input <- readline("Enter enrichment score cutoff: ")
      cutoff <- as.numeric(cutoff_input)
      
      if (is.na(cutoff) || cutoff < 0) {
        cat("\nInvalid cutoff. Please enter a non-negative number.\n")
        next
      }
      
      filtered_data <- filter_by_enrichment(enriched_data, cutoff)
      if (nrow(filtered_data) == 0) {
        cat("\nNo terms pass this cutoff. Please try a lower value.\n")
        next
      }
      
      current_filtered_data <- filtered_data
      top_terms <- get_top_n_terms(filtered_data, 30, current_sort_by)
      current_plot <- create_plot(top_terms, category_order = current_category_order)
      current_cutoff <- cutoff
      
      cat("\nCutoff applied. Use option 2 to display the plot in RStudio.\n")
      
    } else if (action == "2") {
      if (is.null(current_plot)) {
        cat("\nNo plot available. Please create a plot first using option 1.\n")
        next
      }
      
      tryCatch({
        dev.off()
      }, error = function(e) {})
      
      graphics.off()
      dev.new()
      print(current_plot)
      cat("\nPlot displayed in RStudio.\n")
      
    } else if (action == "3") {
      cat("\nSelect category order:")
      cat("\n1: Order by data appearance")
      cat("\n2: Order by plot appearance\n")
      order_choice <- readline("Choose order (1-2): ")
      
      if (order_choice == "1") {
        current_category_order <- "data"
      } else if (order_choice == "2") {
        current_category_order <- "plot"
      } else {
        cat("\nInvalid choice. Keeping current order.\n")
        next
      }
      
      if (!is.null(current_filtered_data)) {
        top_terms <- get_top_n_terms(current_filtered_data, 30, current_sort_by)
        current_plot <- create_plot(top_terms, category_order = current_category_order)
        cat("\nPlot updated with new category order. Use option 2 to display.\n")
      } else {
        cat("\nNo filtered data available. Please set a cutoff first using option 1.\n")
      }
      
    } else if (action == "4") {
      if (is.null(current_plot)) {
        cat("\nNo plot available. Please create a plot first using option 1.\n")
        next
      }
      
      cat("\nSelect action:")
      cat("\n1: Save plot")
      cat("\n2: Return to main menu\n")
      save_choice <- readline("Choose action (1-2): ")
      
      if (save_choice == "1") {
        filename <- readline("Enter filename for plot (default: GO_BP_Simplified_dotplot.pdf): ")
        if (filename == "") filename <- "GO_BP_Simplified_dotplot.pdf"
        if (!grepl("\\.pdf$", filename)) filename <- paste0(filename, ".pdf")
        
        tryCatch({
          ggsave(filename, plot = current_plot, width = 6, height = 6, limitsize = FALSE)
          cat("Plot saved as", filename, "\n")
        }, error = function(e) {
          cat("Error saving plot:", e$message, "\n")
        })
      } else if (save_choice == "2") {
        cat("\nReturning to main menu.\n")
      } else {
        cat("\nInvalid choice. Returning to main menu.\n")
      }
      
    } else if (action == "5") {
      cat("\nSelect action:")
      cat("\n1: Export data")
      cat("\n2: Return to main menu\n")
      export_choice <- readline("Choose action (1-2): ")
      
      if (export_choice == "1") {
        export_data(enriched_data, prompt = TRUE)
        cat("\nData exported. Continuing with visualization.\n")
      } else if (export_choice == "2") {
        cat("\nReturning to main menu.\n")
      } else {
        cat("\nInvalid choice. Returning to main menu.\n")
      }
      
    } else if (action == "6") {
      cat("\nSelect sorting method:")
      cat("\n1: Sort by adjusted p-value (lowest first)")
      cat("\n2: Sort by enrichment score (highest first)\n")
      sort_choice <- readline("Choose sorting method (1-2): ")
      
      if (sort_choice == "1") {
        current_sort_by <- "p.adjust"
      } else if (sort_choice == "2") {
        current_sort_by <- "EnrichmentScore"
      } else {
        cat("\nInvalid choice. Keeping current sorting method.\n")
        next
      }
      
      if (!is.null(current_filtered_data)) {
        top_terms <- get_top_n_terms(current_filtered_data, 30, current_sort_by)
        current_plot <- create_plot(top_terms, category_order = current_category_order)
        cat("\nPlot updated with new sorting method. Use option 2 to display.\n")
      }
      
    } else if (action == "7") {
      return(list(continue = FALSE, plot = current_plot, filtered_data = current_filtered_data))
      
    } else {
      cat("\nInvalid choice. Please enter a number between 1 and 7.\n")
    }
  }
}
# Main execution
main <- function() {
  file_path <- 'your_input_file.xlsx'
  
  cat("Step 1: Calculating Enrichment Score\n")
  enriched_data <- calculate_enrichment_score(file_path)
  
  cat("\nFirst few rows of the enriched data:\n")
  print(head(enriched_data))
  cat("\nColumns in the enriched data:\n")
  print(colnames(enriched_data))
  
  cat("\nStep 2: Interactive Visualization\n")
  vis_results <- handle_visualization(enriched_data)
  
  if (vis_results$continue) {
    cat("\nStep 3: Exporting Data\n")
    export_data(enriched_data, prompt = TRUE)
    cat("\nAnalysis complete.\n")
  } else {
    cat("\nAnalysis stopped after visualization.\n")
  }
  
  return(list(
    complete_data = enriched_data,
    filtered_data = vis_results$filtered_data,
    last_plot = vis_results$plot
  ))
}

# Run the main function
results <- main()
