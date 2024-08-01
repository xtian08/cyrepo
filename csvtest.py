import requests, json, csv
from requests.packages.urllib3.exceptions import InsecureRequestWarning

# Config
output_file="D:\\BigFix_API_Data\\output.csv"
operation = "POST"
certverify = False
url = "https://10.10.10.10:523/api/query"
auth = ("ws1apiquery", "ws1apiquery")
url="https://10.229.130.206:52311/api/query"
auth=("apiquery","Apiqu3ry")
csv_headers = ["ComputerID", "ComputerName", "DeviceType", "Maker", "Model Type", "OS", "IPAddress", "MACAddress", "SerialNumber", "AssetTag", "TestData", "TestData2"]
relevance = """
(
  (concatenation ";" of values of results (item 0 of it, elements of item 1 of it)),
  (if (size of item 2 of it = 1) then (concatenation ";" of values of results (item 0 of it, elements of item 2 of it)) else (if (size of item 2 of it > 1) then ("Property 2 duplicates: " & concatenation "|" of ((name of it) & "=" & (id of it as string)) of elements of item 2 of it) else "Property 2 does not exist")),
  (if (size of item 3 of it = 1) then (concatenation ";" of values of results (item 0 of it, elements of item 3 of it)) else (if (size of item 3 of it > 1) then ("Property 3 duplicates: " & concatenation "|" of ((name of it) & "=" & (id of it as string)) of elements of item 3 of it) else "Property 3 does not exist")),
  (if (size of item 4 of it = 1) then (concatenation ";" of values of results (item 0 of it, elements of item 4 of it)) else (if (size of item 4 of it > 1) then ("Property 4 duplicates: " & concatenation "|" of ((name of it) & "=" & (id of it as string)) of elements of item 4 of it) else "Property 4 does not exist")),
  (if (size of item 5 of it = 1) then (concatenation ";" of values of results (item 0 of it, elements of item 5 of it)) else (if (size of item 5 of it > 1) then ("Property 5 duplicates: " & concatenation "|" of ((name of it) & "=" & (id of it as string)) of elements of item 5 of it) else "Property 5 does not exist")),
  (if (size of item 6 of it = 1) then (concatenation ";" of values of results (item 0 of it, elements of item 6 of it)) else (if (size of item 6 of it > 1) then ("Property 6 duplicates: " & concatenation "|" of ((name of it) & "=" & (id of it as string)) of elements of item 6 of it) else "Property 6 does not exist")),
  (if (size of item 7 of it = 1) then (concatenation ";" of values of results (item 0 of it, elements of item 7 of it)) else (if (size of item 7 of it > 1) then ("Property 7 duplicates: " & concatenation "|" of ((name of it) & "=" & (id of it as string)) of elements of item 7 of it) else "Property 7 does not exist")),
  (if (size of item 8 of it = 1) then (concatenation ";" of values of results (item 0 of it, elements of item 8 of it)) else (if (size of item 8 of it > 1) then ("Property 8 duplicates: " & concatenation "|" of ((name of it) & "=" & (id of it as string)) of elements of item 8 of it) else "Property 8 does not exist")),
  (if (size of item 9 of it = 1) then (concatenation ";" of values of results (item 0 of it, elements of item 9 of it)) else (if (size of item 9 of it > 1) then ("Property 9 duplicates: " & concatenation "|" of ((name of it) & "=" & (id of it as string)) of elements of item 9 of it) else "Property 9 does not exist")),
  (if (size of item 10 of it = 1) then (concatenation ";" of values of results (item 0 of it, elements of item 10 of it)) else (if (size of item 10 of it > 1) then ("Property 10 duplicates: " & concatenation "|" of ((name of it) & "=" & (id of it as string)) of elements of item 10 of it) else "Property 10 does not exist")),
  (if (size of item 11 of it = 1) then (concatenation ";" of values of results (item 0 of it, elements of item 11 of it)) else (if (size of item 11 of it > 1) then ("Property 11 duplicates: " & concatenation "|" of ((name of it) & "=" & (id of it as string)) of elements of item 11 of it) else "Property 11 does not exist")),
  (if (size of item 12 of it = 1) then (concatenation ";" of values of results (item 0 of it, elements of item 12 of it)) else (if (size of item 12 of it > 1) then ("Property 12 duplicates: " & concatenation "|" of ((name of it) & "=" & (id of it as string)) of elements of item 12 of it) else "Property 12 does not exist"))
) of (
  elements of item 0 of it,
  item 1 of it, item 2 of it, item 3 of it, item 4 of it, item 5 of it, item 6 of it,
  item 7 of it, item 8 of it, item 9 of it, item 10 of it, item 11 of it, item 12 of it
) of (
  set of BES computers,
  set of bes properties whose (reserved flag of it and name of it as lowercase = ("id")),
  set of bes properties whose (reserved flag of it and name of it as lowercase = ("computer name")),
  set of bes properties whose (reserved flag of it and name of it as lowercase = ("device type")),
  set of bes properties whose (name of it as lowercase = ("maker")),
  set of bes properties whose (name of it as lowercase = ("model type")),
  set of bes properties whose (reserved flag of it and name of it as lowercase = ("os")),
  set of bes properties whose (reserved flag of it and name of it as lowercase = ("ip address")),
  set of bes properties whose (reserved flag of it and name of it as lowercase = ("mac address")),
  set of bes properties whose (name of it as lowercase = ("serial number")),
  set of bes properties whose (name of it as lowercase = ("asset tag")),
  set of bes properties whose (name of it as lowercase = ("last report time")),
  set of bes properties whose (name of it as lowercase = ("0_serial"))
)
"""

query = {"relevance": relevance, "output": "json"}

# Suppress warnings
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

def handle_response(response):
    if not response.ok:
        raise ValueError(f"HTTP {response.status_code} {response.reason}")
    res_json = response.json()
    if res_json.get("error"):
        raise ValueError(f"Query Error: {res_json['error']}")
    return res_json["result"]

def sanitize_serial(serial, computer_id):
    if not serial or any(x in serial.lower() for x in ["default", "system", "missing", "filled", "123456789"]):
        return f"00DummySN:{computer_id}"
    return serial

def process_result(result):
    result[8] = sanitize_serial(result[8], result[0])
    return result

def write_csv(results):
    with open(output_file, 'w', newline='', encoding="utf-8") as f:
        f.write("sep=|\n")
        writer = csv.writer(f, delimiter='|')
        writer.writerow(csv_headers)
        writer.writerows(map(process_result, results))
    print(f"Wrote to {output_file}")

try:
    res = requests.request(operation, url, data=query, verify=certverify, auth=auth)
    results = handle_response(res)
    write_csv(results)
except Exception as e:
    print(f"Error: {e}")
