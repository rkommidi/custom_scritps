import pandas as pd
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import base64
import sys
import json
from urllib.parse import urlparse

def read_excel(file_path):
    df = pd.read_excel(file_path)
    return df[['id', 'Website', 'Address']]

def load_rules(config_path):
    with open(config_path, 'r') as file:
        return json.load(file)

def get_domain_rules_order(rules, domain):
    """
    Return the order of rules for the given domain.
    """
    domain_rules = rules.get(domain, [])
    return domain_rules

def handle_iframe(driver, iframe_rule):
    """
    Handle the iframe rule.
    """
    for by in iframe_rule:
        value = iframe_rule[by]
        try:
            iframe = driver.find_element(getattr(By, by.upper()), value)
            driver.switch_to.frame(iframe)
            print("Switched to iframe.")
            return
        except Exception as e:
            print(e)
            continue
    print("No iframe found.")

def handle_disclaimer_popup(driver, accept_button_rule):
    """
    Check for the disclaimer popup and click the Accept button if present.
    """
    print(f"accept_button_rule: {accept_button_rule}")
    for by in accept_button_rule:
        value = accept_button_rule[by]
        try:
            print(getattr(By, by.upper()))
            print(value)
            WebDriverWait(driver, 10).until(EC.element_to_be_clickable((getattr(By, by.upper()), value)))
            accept_button = driver.find_element(getattr(By, by.upper()), value)
            driver.execute_script("arguments[0].scrollIntoView(true);", accept_button)
            accept_button.click()
            print("Disclaimer popup accepted.")
            time.sleep(1)  # Wait for the popup to close (adjust as needed)
            return
        except Exception as e:
            print(e)
    print("No disclaimer popup found.")
    driver.switch_to.default_content()

def handle_result_hyperlink(driver, hyperlink_rule):
    """
    Handle the Result_HyperLink rule.
    """
    for by in hyperlink_rule:
        value = hyperlink_rule[by]
        try:
            original_tabs = driver.window_handles
            result_link = driver.find_element(getattr(By, by.upper()), value)
            result_link.click()
            time.sleep(3)

            new_tabs = driver.window_handles
            if len(new_tabs) > len(original_tabs):
                # Switch to the new tab
                driver.switch_to.window(new_tabs[-1])
            return
        except Exception as e:
            print(e)
            continue
    print("No 'View Details' link found.")

def perform_search(driver, address_text, search_field_rule):
    """
    Perform the search and handle the result.
    """
    # Check if Enter key needs to be pressed after entering the address
    isEnter = True
    if "isEnter" in search_field_rule:
        isEnter = search_field_rule["isEnter"]
        del search_field_rule["isEnter"]

    # Split the address text if needed, 0 for street number, 1 for street name, etc.
    if "isSplit" in search_field_rule:
        split_index = search_field_rule["isSplit"]
        if split_index == 0:
            address_text = address_text.split(' ')[split_index]
        else:
            address_text = address_text.split(' ')[split_index:]
        del search_field_rule["isSplit"]

    for by in search_field_rule:
        value = search_field_rule[by]
        print(f"by: {by}")
        print(f"value: {value}")
        print(getattr(By, by.upper()))
        try:
            search_field = driver.find_element(getattr(By, by.upper()), value)
            print(f"Found search field with {by} = '{value}'")
            search_field.send_keys(address_text)
            if isEnter:
                search_field.send_keys(Keys.RETURN)
            time.sleep(3)  # Wait for the search results to load
            return
        except Exception as e:
            continue

    raise Exception("Search field not found on this page.")

def save_to_pdf(driver, address_text, output_file, id):
    """
    Save the current page as a PDF.
    """
    try:
        result = driver.execute_cdp_cmd("Page.printToPDF", {
                    "format": "A4",
                    "printBackground": True
                })
        file_name = f"{output_file}\\{id}_{address_text.replace(',', '').replace(' ', '_')}.pdf"
        
        with open(file_name, "wb") as pdf_file:
            pdf_file.write(base64.b64decode(result['data']))
        
        print(f"PDF saved to {file_name}")
    except Exception as e:
        print(f"Error saving PDF: {e}")
        return False
    
    return True


def search_address(url, address_text, output_file, id, rules):
    # Extract domain from URL
    domain =  urlparse(url).netloc
    # Initialize WebDriver service
    chromedriver_path = r"chromedriver-win64\chromedriver.exe"
    service = Service(chromedriver_path)
    options = webdriver.ChromeOptions()
    driver = webdriver.Chrome(service=service, options=options)
    
    domain_rules_list = get_domain_rules_order(rules, domain)
    print(f"domain_rules_list: {domain_rules_list}")
    try:
        driver.get(url)
        time.sleep(3)  # Wait for the page to load
        for domain_rule in domain_rules_list:
            for selector in domain_rule:
                print(f"selector: {selector}")
                if selector == 'iframe':
                    handle_iframe(driver, domain_rule[selector])                
                if selector == 'accept_button':
                    handle_disclaimer_popup(driver, domain_rule[selector])                
                if selector == 'search_field':
                    perform_search(driver, address_text, domain_rule[selector])
                if selector == 'hyperlink':
                    handle_result_hyperlink(driver, domain_rule[selector])

        result = save_to_pdf(driver, address_text, output_file, id)
        driver.quit()
        return result
    except Exception as e:
        print(f"An error occurred during opening {url}: {e}")
        driver.quit()
        return False
    

def main(file_path, output_file, config_path, target_ids=None):
    df = read_excel(file_path)
    rules = load_rules(config_path)

    for _, row in df.iterrows():
        id = row['id']
        if target_ids and id not in target_ids:
            continue

        url = row['Website']
        address_text = row['Address']

        print(f"\n\n\n*************************************Starting for id: {id}")
        result = search_address(url, address_text, output_file, id, rules)
        if result:
            print(f"Processed {url} for address {address_text}")
        else:
            print(f"Error processing {url} for address {address_text}")

if __name__ == "__main__":
    file_path = r'address_list3.xlsx'
    output_file = r'output'
    config_path = r'rules.config'
    target_ids = None
    if len(sys.argv) > 1:
        target_ids = [int(id) for id in sys.argv[1].split(',')]
    main(file_path, output_file, config_path, target_ids)
