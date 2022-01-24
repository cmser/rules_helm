def _helm_package_impl(ctx):
    ctx.file("WORKSPACE", """workspace(name = "{}")""".format(ctx.attr.name))
    ctx.download_and_extract("{}/{}-{}.{}".format(
        ctx.attr.repo_url,
        ctx.attr.chart,
        ctx.attr.version,
        ctx.attr.extension,
    ), sha256 = ctx.attr.checksum)
    ctx.file(ctx.attr.chart + "/BUILD", """load("@com_github_cmser_rules_helm//chart:defs.bzl", "helm_library")
helm_library(
    name = "chart",
    srcs = glob(include = ["**/*"], exclude = ["Chart.yaml"]),
    entry_point = "Chart.yaml",
    visibility = ["//visibility:public"]
)
""")

helm_package = repository_rule(
    implementation = _helm_package_impl,
    attrs = {
        "version": attr.string(mandatory = True),
        "repo_url": attr.string(mandatory = True),
        "chart": attr.string(mandatory = True),
        "extension": attr.string(default = "tgz"),
        "checksum": attr.string(default = ""),
    }
)