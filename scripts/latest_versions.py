import json
import requests
import re
#from kubernetes import client, config

def istio_release_version():
    istio_release_url = "https://api.github.com/repos/istio/istio/releases"
    maximum_allowed_releases_per_page = "5"
    r = requests.get(istio_release_url, params={"per_page": maximum_allowed_releases_per_page})
    istio_releases = json.loads(r.text)

    # filter to get istio tags
    regex = re.compile("[0-9].[0-9][0-9].[0-9]")
    latest_istio_version = [istio_release["tag_name"] for istio_release in istio_releases
                                        if re.match(regex, istio_release["tag_name"])]
    latest_istio_tag = latest_istio_version[0].split("-")[-1] if len(
        latest_istio_version) > 0 else "error"

    return latest_istio_tag

def external_dns_release_version():
    external_dns_release_url = "https://github.com/kubernetes-sigs/external-dns/releases/latest"
    r = requests.get(external_dns_release_url)
    latest_external_dns_version = r.url.split("tag/")[1].replace("v", "")
    return latest_external_dns_version

def cert_manager_release_version():
    cert_manager_release_url = "https://artifacthub.io/api/v1/packages/helm/cert-manager/cert-manager"
    r = requests.get(cert_manager_release_url)
    cert_manager_releases = json.loads(r.text)
    return cert_manager_releases["version"]

def kiali_release_version():
    kiali_release_url = "https://api.github.com/repos/kiali/kiali/releases"
    maximum_allowed_releases_per_page = "5"
    r = requests.get(kiali_release_url, params={"per_page": maximum_allowed_releases_per_page})
    kiali_releases = json.loads(r.text)

    # filter to get kiali tags
    regex = re.compile("v[0-9].[0-9][0-9].[0-9]")
    latest_kiali_version = [kiali_release["tag_name"] for kiali_release in kiali_releases
                                        if re.match(regex, kiali_release["tag_name"])]
    latest_kiali_tag = latest_kiali_version[0].split("-")[-1] if len(
        latest_kiali_version) > 0 else "error"

    return latest_kiali_tag

def jaeger_release_version():
    jaeger_release_url = "https://api.github.com/repos/jaegertracing/jaeger/releases"
    maximum_allowed_releases_per_page = "5"
    r = requests.get(jaeger_release_url, params={"per_page": maximum_allowed_releases_per_page})
    jaeger_releases = json.loads(r.text)

    # filter to get jaeger tags
    regex = re.compile("Release v[0-9].[0-9][0-9].[0-9]")
    latest_jaeger_version = [jaeger_release["name"] for jaeger_release in jaeger_releases
                                        if re.match(regex, jaeger_release["name"])]
    latest_jaeger_tag = latest_jaeger_version[0].split("-")[-1] if len(
        latest_jaeger_version) > 0 else "error"

    return latest_jaeger_tag.removeprefix('Release ')


#=======================================================================================================================

latest_version = f"""
{{
  "istio_version": "{istio_release_version()}",
  "external_dns_version": "{external_dns_release_version()}",
  "cert_manager_version": "{cert_manager_release_version()}",
  "jaeger_version": "{jaeger_release_version()}",
  "kiali_version": "{kiali_release_version()}"
}}
"""

print(latest_version)

#write latest versions to file
with open('latest_versions.json', 'w') as outfile:
    outfile.write(latest_version)
