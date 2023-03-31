#!C:\Users\Raghav\AppData\Local\Microsoft\WindowsApps\python3.exe

import os
import re
from PyPDF2 import PdfReader

# Set the path to the folder containing the PDF files
folder_path = 'C:\\Users\\Raghav\\pdfs'

# Loop through each PDF file in the folder
for filename in os.listdir(folder_path):
    if filename.endswith('.pdf'):
        # Create the full file path
        file_path = os.path.join(folder_path, filename)

        # Open the PDF file in read-binary mode
        with open(file_path, 'rb') as pdf_file:
            # Create a PDF reader object
            pdf_reader = PdfReader(pdf_file)

            # Get the number of pages in the PDF file
            num_pages = len(pdf_reader.pages)

            # Loop through each page and extract the text
            for page_num in range(num_pages):
                # Get the current page object
                page_obj = pdf_reader.pages[page_num]

                # Extract the text from the page
                page_text = page_obj.extract_text()

                # Print the extracted text
                #print(page_text)
                for line in page_text.split("\n"):
                    if "Policy Number" in line or "POLICY NUMBER" in line or "Order" in line:
                        print(filename, line)
