import json
import os
import sys
from xmlrpc.server import CGIXMLRPCRequestHandler

import requests

base_url = "https://api.datadoghq.com/api/v1/{resource}"
headers = {
    "DD-API-KEY": os.getenv("DATADOG_API_KEY"),
    "DD-APPLICATION-KEY": os.getenv("DATADOG_APP_KEY")
}
dashboard_url = base_url.format(resource="dashboard")
dashboard_json = json.load(open("observe/dashboard.json"))

def upsert_dashboard(dashboard_url, headers, dashboard_json):
    response = requests.get(dashboard_url, headers=headers)
    response.raise_for_status()

    dashboards = response.json()["dashboards"]
    for dashboard in dashboards:
        if dashboard["title"] == dashboard_json["title"]:
            return update_dashboard(dashboard["id"], dashboard_json)

   #  create_dashboard(dashboard_json)


def update_dashboard(dashboard_id, dashboard_json):
    print("updating dashboard {title} with id {id}".format(title=dashboard_json["title"], id=dashboard_id))
    put_response = requests.put(dashboard_url + "/" + dashboard_id, headers=headers, json=dashboard_json)
    put_response.raise_for_status()


upsert_dashboard(dashboard_url, headers, dashboard_json)
