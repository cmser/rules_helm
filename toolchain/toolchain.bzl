load(":providers.bzl", "HelmInfo")

def _helm_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            HelmInfo = HelmInfo(
                bin = ctx.executable.bin,
            ),
        )
    ]

helm_toolchain = rule(
    implementation = _helm_toolchain_impl,
    attrs = {
        "bin": attr.label(allow_single_file = True, executable = True, cfg = "host"),
    },
)