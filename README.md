# R Shiny Dashboard for Data Quality Monitoring

This repository has been prepared as a representative sample of my R Shiny development work. It illustrates the design and implementation of an interactive dashboard developed in a professional context, while respecting confidentiality and intellectual property obligations.

## Overview

This repository contains selected components of an R Shiny application developed to support data quality assessment and monitoring workflows.

The dashboard was designed to assist analysts in reviewing new data transmissions by comparing newly received observations with previously available information and identifying potential revisions and anomalies requiring further investigation.

The application provides an interactive environment where users can explore country-level results, investigate flagged time series, compare previous and updated observations, and review potential outliers through dynamic tables and visualizations.

The repository focuses on the Shiny application layer, including the user interface, reactive server logic, and interactive visualization components. **Supporting data extraction routines, analytical functions, and project-specific processing workflows have been intentionally omitted.**

## Purpose

In many statistical production environments, data are periodically updated through new transmissions that may contain revisions to previously reported observations. Ensuring the consistency and quality of incoming information is an essential step before further analysis and dissemination.

This dashboard was developed to support this validation process by providing an interactive tool for identifying and investigating potential data quality issues. It enables users to:

- compare newly transmitted observations with previously available values;
- identify significant revisions based on configurable thresholds;
- detect potentially anomalous observations in incoming data;
- investigate flagged time series through interactive tables and graphical representations.

By combining automated checks with user-driven exploration, the application supports a more efficient review process and helps analysts focus their attention on observations requiring further assessment.

## Application Workflow

The application was designed to support a structured review process for newly received statistical data transmissions.

1. **Configure the analysis**

   The user specifies the reference period, the transmission time window, and the threshold used to identify significant revisions. These parameters can be updated at any time during the analysis without restarting the application.

2. **Review the overview dashboard**

   After the analysis is initiated, the dashboard presents an overview of all reporting countries. For each country, summary indicators display the number of time series flagged for revisions and potential outliers, allowing users to quickly identify areas requiring further investigation.

3. **Investigate revisions**

   Selecting a reporting country opens a dedicated view where individual time series can be explored. Users can filter available series, compare current and previous observations, review calculated growth rates, and inspect interactive tables and visualisations that facilitate the assessment of revisions.

4. **Investigate potential outliers**

   A dedicated section allows users to review observations identified as potential outliers. Interactive tables and graphical representations help distinguish unusual observations from the remaining values within each time series.

## Technical Implementation

The application was developed entirely in **R** using the **Shiny** framework, with a focus on modularity, interactivity, and maintainability. Although the repository excludes the proprietary analytical functions and data extraction routines, it illustrates the overall architecture of the application and the implementation of the interactive dashboard.

Key implementation aspects include:

- **Reactive programming:** The application relies on `reactiveVal()`, `reactiveValues()`, `observe()`, and `observeEvent()` to manage application state, user interactions, and dynamic updates while avoiding unnecessary computations.

- **Dynamic user interface:** Dashboard components are generated dynamically based on the available data, allowing users to navigate from an overview of reporting countries to detailed analyses of individual time series.

- **Interactive analytical workflow:** Users can configure analysis parameters, filter time series, investigate revisions, review potential outliers, and explore the corresponding tables and visualisations through a responsive interface.

- **Performance considerations:** Intermediate results are cached during the session to minimise repeated computations and improve responsiveness when analysis parameters are updated.

- **Data visualisation:** The application combines tabular summaries with `ggplot2` visualisations to facilitate the interpretation of revisions, growth rates, and potential outliers.

- **Custom interface design:** The user interface combines the `bslib` framework with custom CSS to provide a clean and intuitive layout while maintaining flexibility for future extensions.

The application follows a clear separation of responsibilities between the user interface, reactive application logic, and analytical routines. Data extraction, processing, and domain-specific computations are implemented in dedicated scripts (not included in this repository), allowing the Shiny application to focus on orchestration, user interaction, and presentation of results.

## Repository Contents

This repository contains the Shiny application layer used to implement the interactive dashboard.

Included:

- `app.R`: User interface, server logic, reactive workflows, and visualisation components.

Intentionally omitted:

- data extraction routines;
- database connections;
- supporting analytical functions;
- statistical processing algorithms;
- project-specific assets and configuration files.

These components have been excluded to comply with confidentiality and intellectual property obligations while preserving the application's overall architecture and coding approach.

## Confidentiality Notice

The original application was developed in a professional environment.

To comply with intellectual property and confidentiality obligations, this repository contains only selected components of the application. All project-specific business logic, analytical functions, data sources, database connections, and other proprietary elements have been removed or replaced where appropriate.

The repository is intended solely to demonstrate the design and implementation of the Shiny application, including its user interface, reactive programming model, and overall software architecture.
