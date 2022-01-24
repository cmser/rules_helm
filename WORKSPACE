workspace(name = "com_github_cmser_rules_helm")

load("//helm:repositories.bzl", "helm_register_toolchains")

helm_register_toolchains()

load("@com_github_cmser_rules_helm//repo:helm_package.bzl", "helm_package")

helm_package(
    name = "helm_traefik_io_traefik",
    repo_url = "https://helm.traefik.io/traefik",
    chart = "traefik",
    version = "10.9.1",
    checksum = "5ccd432e87d4d7310415e0796cd43b720bf5d36817b13a0f3fb48587ced0b864"
)