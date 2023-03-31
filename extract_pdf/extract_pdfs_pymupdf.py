#!C:\Users\Raghav\AppData\Local\Microsoft\WindowsApps\python3.exe

import os
import re
import fitz

# Set the path to the folder containing the PDF files
folder_path = 'C:\\Users\\Raghav\\pdfs'

# Loop through each PDF file in the folder
for filename in os.listdir(folder_path):
    if filename.endswith('.pdf'):
        # Create the full file path
        file_path = os.path.join(folder_path, filename)
        
        # Open the PDF file
        pdf_file = fitz.open(file_path)
        # Iterate over each page in the PDF
        for page_num in range(pdf_file.page_count):
            # Get the page object
            page = pdf_file[page_num]
    
            # Extract the text from the page
            page_text = page.get_text()
    
            # Print the text
            #print(f"Page {page_num+1}:")
            #print(page_text)
            title = ""
            for i,line in enumerate(page_text.split("\n")):
                if i == 4:
                    title = line
                    print(line,i)
                if "Policy Number" in line or "POLICY NUMBER" in line or "Order" in line:
                    #match = re.search(r"(?i)policy number:\s*([\d-]+)", line)
                    match = re.search(r"(?i)Order no:\s*([\w]+)", line)
                    policy_number = match.group(1)
                    print(filename, title, policy_number)

    
        # Close the PDF file
        pdf_file.close()
