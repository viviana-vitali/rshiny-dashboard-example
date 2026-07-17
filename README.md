# R Shiny Dashboard for Data Quality Monitoring

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
