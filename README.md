# go_enrichment_plotting
# GO Enrichment Visualization and Analysis Script

This R script visualizes and analyzes pre-existing Gene Ontology (GO) enrichment data. It's designed to work with GO enrichment results from any tool, provided the output contains the required columns. The script can handle data from a single group or multiple groups (defined in the Cluster column) and offers an interactive, step-by-step process for calculating enrichment scores, creating plots, and exporting data.

## Prerequisites

### Installing R and RStudio

1. Download and install R from [The Comprehensive R Archive Network (CRAN)](https://cran.r-project.org/).
2. Download and install RStudio from the [RStudio website](https://www.rstudio.com/products/rstudio/download/).

### Required R Packages

Install the following R packages by running these commands in R or RStudio:

```R
install.packages(c("ggplot2", "dplyr", "tidyr", "stringr", "readxl", "writexl", "extrafont"))
```

## Data Requirements

The script can visualize GO enrichment results from any source, as long as the input file (in Excel format, .xlsx) contains the following required columns:

- Cluster (defines the group; can be a single group or multiple)
- Description (GO term description)
- GeneRatio
- BgRatio
- p.adjust (adjusted p-value)

Optional but recommended column:
- User_Defined_Category (for grouping and ordering GO terms)

### Data Ordering

If your data includes a User_Defined_Category column, the script preserves the order of categories as they appear in your input data. To customize the order of categories:

1. Open your input Excel file.
2. Arrange the rows so that the User_Defined_Category column is in your desired order.
3. Save the Excel file.

The script will use this order for plotting.

## Usage

1. Clone this repository or download the R script.
2. Open the script in RStudio.
3. Modify the `file_path` variable in the `main` function to point to your input Excel file:

   ```R
   file_path <- 'path/to/your/data.xlsx'
   ```

4. Run the script by calling the `main` function:

   ```R
   main(enrichment_score_cutoff = 2)
   ```

   Adjust the `enrichment_score_cutoff` value as needed. Set it to 0 to include all terms.

5. Follow the interactive prompts to proceed through each step of the analysis.

## Script Functionality

The script performs the following steps:

1. Reads the pre-existing GO enrichment data.
2. Calculates Enrichment Scores based on GeneRatio and BgRatio.
3. Creates a dot plot visualizing the GO terms, their adjusted p-values, and Enrichment Scores.
4. Exports the complete dataset, including calculated Enrichment Scores.

At each step, you'll be prompted to continue or stop the analysis.

## Output

- A PDF file named "GO_categorized_dotplot.pdf" containing the visualization.
- An Excel file named "enrichment_data.xlsx" containing all the data, including calculated Enrichment Scores.

## Contributing

Feel free to fork this repository and submit pull requests with any enhancements.

## License

This project is licensed under the MIT License:

MIT License

Copyright (c) 2023 [Kamal Md Mostafa]
