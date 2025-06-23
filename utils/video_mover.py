import csv
import os
import shutil
import pandas as pd
from tqdm import tqdm

# Specify the paths
csv_file = '/home/boyan/sandbox/Jake_roast/My_Scripts/Tables/extracted_subjects.csv'  # CSV file with .mp4 file names (one per line)
source_folder = '/home/boyan/sandbox/Jake_Data/Videos'
destination_folder = '/home/boyan/sandbox/Jake_Data/ti_dataset_segVideos'  # Folder where files should be moved
file_suffix = '.mp4'  # File suffix

# Ensure destination folder exists
os.makedirs(destination_folder, exist_ok=True)

# Read the CSV file and create a list of file names
with open(csv_file, newline='', encoding='utf-8') as f:
    reader = csv.reader(f)
    # Assuming each row has one column with the file name
    files_to_move = [row[0].strip() for row in reader if row]

suffix_files=[]
for f in files_to_move:
    suffix_files.append(f'{f}{file_suffix}')

failed_videos = []
# Iterate over each file name from the CSV file
for file_name in tqdm(suffix_files):
    src_file = os.path.join(source_folder, file_name)
    dst_file = os.path.join(destination_folder, file_name)
    
    # Check if the file exists and is an .mp4 file
    if os.path.isfile(src_file) and file_name.lower().endswith('.mp4'):
        try:
            shutil.copy(src_file, dst_file)
            tqdm.write(f"Moved: {src_file} to {dst_file}")
        except Exception as e:
            tqdm.write(f"Error moving {src_file}: {e}")
            failed_videos.append(src_file)
    else:
        tqdm.write(f"File does not exist or is not an .mp4 file: {src_file}")
        failed_videos.append(src_file)
pd.DataFrame(failed_videos).to_csv(os.path.join(destination_folder,'failed_videos.csv'), index=False, header=False) 