import os
import pandas as pd
import requests
import logging
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor

# Setup logging to capture errors or important logs
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

csv_path = 'nrega_data_files/csv/assets/'


def download_html_for_collection_sno(collection_sno, district_name, html_save_path, session):
    """
    This function downloads the HTML content for the given collection_sno and saves it to the specified directory.
    """
    url = "https://bhuvan-app2.nrsc.gov.in/mgnrega/usrtasks/nrega_phase2/get/get_details.php"
    params = {"sno": collection_sno}
    
    try:
        response = session.get(url, params=params, timeout=10)
        
        if response.status_code == 200:
            os.makedirs(html_save_path, exist_ok=True)
            
            file_name = f'{collection_sno}_work_data.html'
            file_path = os.path.join(html_save_path, file_name)
            
            with open(file_path, 'w', encoding='utf-8') as file:
                file.write(response.text)
            
            logging.info(f"Saved HTML for collection_sno {collection_sno} in {file_path}")
        else:
            logging.warning(f"Failed to download HTML for collection_sno {collection_sno}. Status Code: {response.status_code}")
    except Exception as e:
        logging.error(f"Error while downloading HTML for collection_sno {collection_sno}: {e}")

def extract_data_from_html(html_file):
    """
    This function extracts the relevant data from the saved HTML file.
    """
    try:
        with open(html_file, 'r', encoding='utf-8') as file:
            soup = BeautifulSoup(file, 'html.parser')
            data = {
            "collection_sno": os.path.basename(html_file).split('_')[0],
            "Category": None,
            "Sub-Category": None,
            "Asset Name": None,
            "Work Name": None,
            "Work Type": None,
            "Estimated Cost": 0,
            "Start Location": -1,
            "End Location": -1,
            "Unskilled": 0,
            "Semi-Skilled": 0,
            "Skilled": 0,
            "Material": 0,
            "Total_Expenditure": 0,
            "Unskilled_Persondays": -1,
            "Semi-skilled_Persondays": -1,
            "Total_persondays": -1,
            "Unskilled_persons": -1,
            "Semi-skilled_persons": -1,
            "Total_persons": -1,
            "Work_start_date": -1,
            "HyperLink": -1,
        }

        td_elements = soup.find_all('td')
        for i in range(len(td_elements) - 1):
            text = td_elements[i].get_text(strip=True)
            if text == "Category":
                data["Category"] = td_elements[i + 1].get_text(strip=True)
            elif text == "Sub-Category":
                data["Sub-Category"] = td_elements[i + 1].get_text(strip=True)
            elif text == "Asset Name":
                data["Asset Name"] = td_elements[i + 1].get_text(strip=True)
            elif text == "Work Name":
                data["Work Name"] = td_elements[i + 1].get_text(strip=True)
            elif text == "Work Type":
                data["Work Type"] = data["Sub-Category"]
            elif text == "Cumulative Cost of Asset":
                data["Estimated Cost"] = td_elements[i + 1].get_text(strip=True)
            elif text == "Expenditure Unskilled":
                data["Unskilled"] = td_elements[i + 1].get_text(strip=True)
            elif text == "Expenditure Material/Skilled":
                data["Material"] = td_elements[i + 1].get_text(strip=True)
            elif text == "Work Start Date":
                data["Work_start_date"] = td_elements[i + 1].get_text(strip=True)

        # Calculate Total_Expenditure
        unskilled = float(data["Unskilled"] or 0)
        material = float(data["Material"] or 0)
        data["Total_Expenditure"] = unskilled + material

        return data
    except Exception as e:
        logging.error(f"Error while extracting data from {html_file}: {e}")
        return None

def download_html_for_all_districts(state_name):
    """
    This function downloads HTML files for all districts in the given state.
    """
    state_folder = os.path.join(csv_path, state_name)
    
    if not os.path.exists(state_folder):
        logging.error(f"State folder not found: {state_folder}")
        return
    
    # Loop through all CSV files in the state folder
    for district_file in os.listdir(state_folder):
        if district_file.endswith('.csv'):
            district_name = district_file.replace('_bhuvan_lat_lon.csv', '')
            csv_file_path = os.path.join(state_folder, district_file)
            logging.info(f"Downloading HTML for district: {district_name}")
            
            try:
                df = pd.read_csv(csv_file_path) 
                if 'collection_sno' in df.columns:
                    session = requests.Session()
                    district_html_folder = os.path.join(state_folder, district_name, "html_files")
                    os.makedirs(district_html_folder, exist_ok=True)
                    
                    with ThreadPoolExecutor(max_workers=100) as executor:
                        futures = {executor.submit(download_html_for_collection_sno, collection_sno, district_name, district_html_folder, session): collection_sno for collection_sno in df['collection_sno']}   
                        for future in futures:
                            future.result()
                    
                    logging.info(f"Completed HTML download for district {district_name}.")
                else:
                    logging.warning(f"Column 'collection_sno' not found in {district_file}. Skipping file.")
            except Exception as e:
                logging.error(f"Error while processing {district_file}: {e}")

def process_html_files_and_extract_data(state_name):
    """
    This function processes the saved HTML files and extracts the relevant data from each file.
    """
    state_folder = os.path.join(csv_path, state_name)
    
    if not os.path.exists(state_folder):
        logging.error(f"State folder not found: {state_folder}")
        return
    
    # Loop through all CSV files in the state folder
    for district_file in os.listdir(state_folder):
        if district_file.endswith('.csv'):
            district_name = district_file.replace('_bhuvan_lat_lon.csv', '')
            csv_file_path = os.path.join(state_folder, district_file)
            logging.info(f"Processing HTML files for district: {district_name}")
            
            try:
                df = pd.read_csv(csv_file_path)
                if 'collection_sno' in df.columns:
                    all_data = []
                    
                    for collection_sno in df['collection_sno']:
                        html_file_path = os.path.join(state_folder, district_name, "html_files", f"{collection_sno}_work_data.html")
                        
                        if os.path.exists(html_file_path):
                            data = extract_data_from_html(html_file_path)
                            if data:
                                all_data.append(data)
                    
                    if all_data:
                        new_df = pd.DataFrame(all_data)
                        
                        output_csv_file = os.path.join(state_folder, district_name + "_processed.csv")
                        new_df.to_csv(output_csv_file, index=False)
                        logging.info(f"Saved processed data to {output_csv_file}")
                    else:
                        logging.warning(f"No data extracted for district {district_name}.")
                else:
                    logging.warning(f"Column 'collection_sno' not found in {district_file}. Skipping file.")
            except Exception as e:
                logging.error(f"Error while processing {district_file}: {e}")

# Example usage:
state_name = 'ANDAMAN AND NICOBAR'

# download_html_for_all_districts(state_name, csv_path)
# process_html_files_and_extract_data(state_name, csv_path)
