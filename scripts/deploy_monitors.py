import json
import os
import sys
import requests
from jinja2 import Template

data = {
    "cluster": sys.argv[1],
    "alert_channel": sys.argv[2]
}

monitor_url = "https://api.datadoghq.com/api/v1/monitor"
headers = {
    "DD-API-KEY": os.getenv("DATADOG_API_KEY"),
    "DD-APPLICATION-KEY": os.getenv("DATADOG_APP_KEY")
}

monitors_dir = "observe/monitors"
monitors_files = [os.path.join(monitors_dir, file) for file in os.listdir(monitors_dir) if file.endswith(".json")]


def upsert_all_monitors(monitor_url, headers, monitors_files, data):
    """
    primary function. loops through all monitor definitions in the monitors directory and create/updates the monitor
    configuration in datadog
    """
    response = requests.get(monitor_url, headers=headers)
    response.raise_for_status()

    existing_monitors = {monitor["name"]: monitor for monitor in response.json()}

    # fetch the list of monitor templates
    for idx, monitor in enumerate(monitors_files):
        env_monitor = env_monitor_file_path(monitor)
        if os.path.exists(env_monitor):
            monitors_files[idx] = env_monitor

    for monitor_template in monitors_files:
        monitor_json = json.loads(Template(open(monitor_template).read()).render(data))
        if monitor_json["name"] in existing_monitors:
            monitor_id = existing_monitors[monitor_json["name"]]["id"]
            update_monitor(monitor_id, monitor_json, monitor_url, headers)
        else:
            create_monitor(monitor_json, monitor_url, headers)

def env_monitor_file_path(monitor_file):
    """
    return the paths to the monitor templates in the observe folder
    """
    monitor_file_name = monitor_file.split("/")[-1]
    overwrite_file_path = "observe/monitors/{monitor}".format(monitor=monitor_file_name)
    return overwrite_file_path

def update_monitor(monitor_id, monitor_json, monitor_url, headers):
    """
    update changes to monitor definition in datadog
    """
    print(f"updating monitor {monitor_json['name']} id:{monitor_id}")
    put_response = requests.put(monitor_url + "/" + str(monitor_id),
                                    headers=headers,
                                    json=monitor_json)

    put_response.raise_for_status()
    return put_response

def create_monitor(monitor_json, monitor_url, headers):
    """
    create a new monitor definition in datadog
    """
    print(f"creating new monitor {monitor_json['name']}")
    post_response = requests.post(monitor_url, headers=headers, json=monitor_json)
    post_response.raise_for_status()
    return post_response

upsert_all_monitors(monitor_url, headers, monitors_files, data)
