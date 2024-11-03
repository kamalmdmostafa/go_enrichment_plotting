# GO Term Enrichment Score Analysis and Visualization

This R script calculates enrichment scores for GO (Gene Ontology) terms and provides interactive visualization. The enrichment score helps identify GO terms that are significantly overrepresented in your gene clusters compared to the background, followed by customizable visualization of the results.

## Enrichment Score Calculation

### Formula
The enrichment score is calculated as:
```
EnrichmentScore = (GeneRatio_numeric / BgRatio_numeric)

Where:
GeneRatio_numeric = number of genes in cluster with GO term / total genes in cluster
BgRatio_numeric = number of genes in background with GO term / total genes in background
```

For example:
- If 5 out of 100 genes in your cluster have a GO term (GeneRatio = "5/100")
- And 20 out of 1000 genes in background have the same GO term (BgRatio = "20/1000")
- The enrichment score would be: (5/100)/(20/1000) = 2.5

### Interpretation
- Score > 1: GO term is enriched in your cluster compared to background
- Score = 1: GO term appears at expected frequency
- Score < 1: GO term is depleted in your cluster

The higher the enrichment score, the stronger the enrichment of that GO term in your cluster.

## Prerequisites

### Installing R and RStudio

1. Install R:
   - Visit [R Project website](https://www.r-project.org/)
   - Click on "CRAN" under "Download"
   - Choose your nearest mirror
   - Select your operating system (Windows/Mac/Linux)
   - Download and install the latest version of R

2. Install RStudio:
   - Visit [RStudio website](https://www.rstudio.com/products/rstudio/download/)
   - Download the free RStudio Desktop version
   - Install the downloaded file

### Required R Packages

Run these commands in RStudio to install required packages:
```R
install.packages(c("ggplot2", "dplyr", "tidyr", "stringr", "readxl", "writexl", "extrafont"))
```

## Input File Requirements

### File Format
- Excel file (.xlsx)
- File should be placed in the same directory as the script

### Required Columns
Your Excel file must contain these columns:
1. `Cluster`: Cluster identifiers
2. `Description`: GO term descriptions
3. `GeneRatio`: Format must be "n/m" where:
   - n = number of genes in cluster with this GO term
   - m = total number of genes in cluster
4. `BgRatio`: Format must be "N/M" where:
   - N = number of genes in background with this GO term
   - M = total number of background genes
5. `p.adjust`: Adjusted p-values (numeric)

### Optional Column
- `User_Defined_Category`: Category labels for GO terms (for visualization grouping)

## Analysis and Visualization Features

### Analysis Features
1. **Enrichment Score Calculation**
   - Automatically calculates enrichment scores from ratio data
   - Handles multiple clusters simultaneously
   - Preserves statistical significance information (p.adjust)

2. **Data Filtering**
   - Filter by minimum enrichment score
   - Maintains cluster-specific context
   - Retains statistical significance information

3. **Term Selection**
   - Select top terms by:
     - Adjusted p-value (statistical significance)
     - Enrichment score (effect size)
   - Cluster-specific selection
   - Customizable number of terms (default: top 30)

### Interactive Menu Options

1. **Enter new enrichment score cutoff**
   - Accept any positive number (e.g., 1.5, 2, 2.5)
   - Filter GO terms based on enrichment score threshold
   - Shows summary of filtered results

2. **Plot in R Studio**
   - Displays the current visualization
   - Shows enrichment scores as point sizes
   - Shows adjusted p-values as color gradient (red to blue)
   - Displays categories as background colors if provided

3. **Change category order**
   - Option 1: Order by data appearance
   - Option 2: Order by plot appearance (based on maximum enrichment scores)

4. **Save current plot**
   - Default filename: GO_BP_Simplified_dotplot.pdf
   - Custom filename option
   - Saves as PDF format
   - Fixed dimensions (6x6 inches)

5. **Export data**
   - Default filename: enrichment_data.xlsx
   - Custom filename option
   - Exports complete dataset with calculations
   - Continues visualization after export

6. **Change sorting method**
   - Option 1: Sort by adjusted p-value (lowest first)
   - Option 2: Sort by enrichment score (highest first)
   - Affects the selection of top 30 terms per cluster

7. **Quit visualization**
   - Exits the visualization process
   - Returns to main program

## Output Data Structure

### Calculated Columns
The script adds these calculated columns to your data:
1. `GeneRatio_k`: Numerator of GeneRatio
2. `GeneRatio_n`: Denominator of GeneRatio
3. `BgRatio_K`: Numerator of BgRatio
4. `BgRatio_N`: Denominator of BgRatio
5. `GeneRatio_numeric`: Calculated numeric GeneRatio
6. `BgRatio_numeric`: Calculated numeric BgRatio
7. `EnrichmentScore`: Final enrichment score

### Plot Features
- Point size: Represents Enrichment Score
- Point color: Represents adjusted p-value (red: low, blue: high)
- Background color: Represents User Defined Category (if provided)
- X-axis: Clusters
- Y-axis: GO term descriptions (truncated to 45 characters)

## Output Files

### Plot File (PDF)
- Default name: GO_BP_Simplified_dotplot.pdf
- Format: PDF
- Size: 6x6 inches
- Resolution: Print quality

### Data Export (Excel)
- Default name: enrichment_data.xlsx
- Format: Excel (.xlsx)
- Contains all original and calculated columns

## Notes

- The script uses Times New Roman font. Make sure it's installed on your system
- Windows users should use `loadfonts(device = "win")`
- Mac users should use `loadfonts(device = "mac")`
- The visualization shows top 30 terms per cluster by default
- All filtered terms must meet the enrichment score cutoff
- Categories are optional but enhance visual grouping

## Troubleshooting

### Font Issues
If you encounter font-related errors:
```R
# Run this command to install fonts
extrafont::font_import()
# Then reload fonts
loadfonts(device = "win") # or "mac" for MacOS
```

### Common Issues
1. Missing columns in input file
   - Check column names match exactly
   - Ensure all required columns are present

2. Invalid ratio formats
   - Check GeneRatio and BgRatio follow "n/m" format
   - Ensure numbers are positive integers

3. Plot display issues
   - Try closing all existing plot windows
   - Use the 'Plot in RStudio' option again

## Statistical Notes

- The script calculates enrichment scores but does not calculate p-values
- P-values should be calculated by your GO enrichment analysis tool
- Both metrics (enrichment score and p-value) should be considered for interpretation

## File Structure
```
.
├── script.R                     # Main script file
├── your_input_file.xlsx        # Your GO term data
├── GO_BP_Simplified_dotplot.pdf # Generated plot (default name)
└── enrichment_data.xlsx        # Exported data (default name)
```

## Contributing

Feel free to submit issues and enhancement requests through GitHub.

## License

[Add your preferred license]

## Contact

[Add your contact information]

## Citation

If you use this script in your research, please cite:
[Add citation information]

