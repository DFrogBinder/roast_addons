import csv
import os
import shutil

from tqdm import tqdm

# Specify the paths
csv_file = '/home/boyan/sandbox/Jake_roast/My_Scripts/Tables/extracted_subjects.csv'         # CSV file with directory names (one per line)
source_folder = '/home/boyan/sandbox/Jake_Data/Videos'
destination_folder = '/home/boyan/sandbox/Jake_Data/ti_dataset_segVideos'    # Folder where directories should be copied

# Ensure destination folder exists
os.makedirs(destination_folder, exist_ok=True)

# Read the CSV file and create a list of directory names
with open(csv_file, newline='', encoding='utf-8') as f:
    reader = csv.reader(f)
    # Assuming each row has one column with the directory name
    directories_to_copy = [row[0].strip() for row in reader if row]

# Iterate over each directory name from the CSV file
for dir_name in tqdm(directories_to_copy):
    src_path = os.path.join(source_folder, dir_name)
    dst_path = os.path.join(destination_folder, dir_name)
    
    # Check if the directory exists in the source folder
    if os.path.isdir(src_path):
        try:
            shutil.copytree(src_path, dst_path)
            tqdm.write(f"Copied: {src_path} to {dst_path}")
        except FileExistsError:
            tqdm.write(f"Destination already exists for: {dst_path}")
        except Exception as e:
            tqdm.write(f"Error copying {src_path}: {e}")
    else:
        tqdm.write(f"Directory does not exist: {src_path}")

