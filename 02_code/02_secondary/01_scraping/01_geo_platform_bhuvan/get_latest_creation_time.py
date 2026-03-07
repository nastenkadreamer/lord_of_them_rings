import pandas as pd
import os
from datetime import datetime

# List of possible date formats
date_formats = [
    "%d-%b-%y %H:%M:%S.%f",
    "%d-%b-%y %H:%M:%S",
    "%d-%m-%y %H:%M:%S.%f",
    "%d-%m-%y %H:%M:%S",
    "%d-%b-%Y %H:%M:%S.%f",
    "%d-%b-%Y %H:%M:%S",
    "%d-%m-%Y %H:%M:%S.%f",
    "%d-%m-%Y %H:%M:%S",
    "%Y-%m-%d %H:%M:%S.%f",
    "%Y-%m-%d %H:%M:%S",
]

# Function to parse dates with multiple formats
def parse_date(date_str):
    for fmt in date_formats:
        try:
            return datetime.strptime(date_str, fmt)
        except (ValueError, TypeError):
            continue  # If format doesn't match, try the next one
    return pd.NaT  # If none of the formats work, return NaT (Not a Time)

# Directory containing the district CSV files
folder_path = 'MAHARASHTRA'  # Replace with the path to your folder
creation_folder = 'nrega_data_files/csv/Creation_assets/' + folder_path.upper()

# Loop through each file in the folder
for filename in os.listdir(folder_path):
    if filename.endswith(".csv"):  # Check if the file is a CSV file
        file_path = os.path.join(folder_path, filename)
        
        # Read the CSV file into a DataFrame
        df = pd.read_csv(file_path)
        
        # Apply the parse_date function to the 'creation_time' column
        df['creation_time'] = df['creation_time'].apply(parse_date)
        
        # Check for any errors in conversion (NaT means not a time, or failed parsing)
        if df['creation_time'].isna().sum() > 0:
            print(f"Some entries could not be parsed in {filename}:")
            print(df[df['creation_time'].isna()])
        
        # Group by 'Panchayat_ID', 'Panchayat', and 'block', then get the latest 'creation_time'
        latest_creation_times = df.groupby(['Panchayat_ID', 'Panchayat', 'Block'], as_index=False)['creation_time'].max()
        
        # Convert 'creation_time' to only the date (YYYY-MM-DD)
        latest_creation_times['creation_time'] = latest_creation_times['creation_time'].dt.date
        
        # Add a new column 'district_name' (based on the file name)
        latest_creation_times['district_name'] = filename.split('.')[0]
        
        # Display the result with the new column
        print(f"Processed {filename}")
        
        # Save the result to an Excel file with district name (filename)
        output_file = os.path.join(creation_folder, f"{filename.split('.')[0].capitalize()}_latest_creation_times.xlsx")
        latest_creation_times.to_excel(output_file, index=False)  # Save to Excel

        print(f"Saved {output_file}")
