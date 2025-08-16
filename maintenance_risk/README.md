# Maintenance Risk Prediction

This project aims to predict the probability of machine failure using sensor data from industrial equipment.  
The workflow follows a standard machine learning pipeline, from exploration to modeling and evaluation.

## Dataset
The dataset comes from Kaggle: [Machine Failure Prediction using Sensor Data](https://www.kaggle.com/datasets/umerrtx/machine-failure-prediction-using-sensor-data).

## Project Structure
- **Exploration**: Initial analysis of the dataset, checking distributions, missing values, and correlations.  
- **Preprocessing**: Handling missing values, scaling, encoding, and splitting data into train/test sets.  
- **Baseline Modeling**: Logistic Regression as a benchmark.  
- **Advanced Modeling**: Random Forest and XGBoost, including:
  - Accuracy, precision, recall, F1-score, ROC-AUC  
  - Feature importance analysis
