"""
This script scrapes images from the Bhuvan geospatial platform for selected assets in the Barwani pilot project.
It downloads asset images based on data from a sampled asset Excel file for further analysis.
"""

import pandas as pd
import requests
from pathlib import Path
from PIL import Image
from io import BytesIO
import os

# Set your username here
username = "anind"  # Replace with your username or any thing that can make this code work on your system. You can also use os.getlogin() to get the current username dynamically.

# Define the root path
root_path = Path(f"C:/Users/{username}/Dropbox/Building Resilience Barwani")

# Define data directory
data_dir = root_path / "04 Data"

# Read the XLSX file
xlsx_file = data_dir / "01_data" / "03 Clean" / "02_asset_audit" / "barwani_pilot_selected_assets_appended.xlsx"
df = pd.read_excel(xlsx_file)

# Create base Images directory
base_dir = data_dir / "01_data" / "01 Raw" / "02_Asset_Audit" / "bhuvan_asset_images"
base_dir.mkdir(exist_ok=True)

# Iterate through each row
for idx, row in df.iterrows():
    if row['completed_asset'] == 0:
        continue
    if pd.isna(row['image_path1']) or row['image_path1'] == '' or pd.isna(row['image_path2']) or row['image_path2'] == '':
        continue
    block = row['block']  # Get the block name
    panchayat = row['panchayat']  
    asset_id = row['asset_id']    
    image_path1 = row['image_path1']  
    image_path2 = row['image_path2']  
    
    # Create block folder
    block_dir = base_dir / block
    block_dir.mkdir(exist_ok=True)
    
    # Create panchayat folder
    panchayat_dir = block_dir / panchayat
    panchayat_dir.mkdir(parents=True, exist_ok=True)
    
    # Download and save first image
    try:
        response = requests.get(image_path1, timeout=10)
        response.raise_for_status()
        img = Image.open(BytesIO(response.content))
        img_path = panchayat_dir / f'{asset_id}_1.jpg'
        img.save(img_path)
        print(f'Saved: {img_path}')
    except Exception as e:
        print(f'Failed to download {image_path1}: {e}')
    
    # Download and save second image with suffix
    try:
        response = requests.get(image_path2, timeout=10)
        response.raise_for_status()
        img = Image.open(BytesIO(response.content))
        img_path = panchayat_dir / f'{asset_id}_2.jpg'
        img.save(img_path)
        print(f'Saved: {img_path}')
    except Exception as e:
        print(f'Failed to download {image_path2}: {e}')

print('Image scraping completed!')