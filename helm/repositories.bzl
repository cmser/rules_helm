load("//helm:toolchains_repo.bzl", "PLATFORMS", "toolchains_repo")

def _helm_repositories_impl(repository_ctx):
    repository_ctx.download_and_extract(
        url = repository_ctx.attr.url,
        stripPrefix = repository_ctx.attr.strip_prefix
    )
    build_content = """#Generated by helm/repositories.bzl
load("@com_github_cmser_rules_helm//toolchain:toolchain.bzl", "helm_toolchain")
helm_toolchain(name = "helm_toolchain", bin = "helm")
"""

    # Base BUILD file for this repository
    repository_ctx.file("BUILD.bazel", build_content)

helm_repositories = repository_rule(
    implementation = _helm_repositories_impl,
    attrs = {
        "url": attr.string(mandatory = True),
        "platform": attr.string(mandatory = True),
        "strip_prefix": attr.string(mandatory = True),
    }
)

def helm_register_toolchains(name = "helm", version = "v3.7.2", register = True, **kwargs):
    for platform, platform_value in PLATFORMS.items():
        helm_repositories(
            name = name + "_" + platform,
            platform = platform,
            strip_prefix = platform_value.strip_prefix,
            url = platform_value.url.format(version),
            **kwargs
        )
        if register:
            native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    toolchains_repo(
        name = name + "_toolchains",
        user_repository_name = name,
    )