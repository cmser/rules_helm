HelmChartInfo = provider(
    fields = ["sources", "name", "root", "label"]
)

_RUN_TEMPLATE = """#!/bin/bash
{} template {} {} 2> >(grep -v 'found symbolic link' >&2) > {}
"""

def _write_exec(ctx, out, entry_point):
    exec = ctx.actions.declare_file("helm_run.sh")
    ctx.actions.write(
        content = _RUN_TEMPLATE.format(
            ctx.toolchains["@com_github_cmser_rules_helm//toolchain:toolchain_type"].HelmInfo.bin.path,
            ctx.label.package,
            entry_point.dirname,
            out.path
        ),
        output = exec,
        is_executable = True
    )
    return exec

def _compute_substitutions(ctx):
    substitutions = {}
    sources = []
    for dep in ctx.attr.deps:
        info = dep[HelmChartInfo]
        for f in info.sources.to_list():
            path = f.path.replace(ctx.bin_dir.path + "/" + info.label.workspace_root, "")
            s = ctx.actions.declare_file("charts{}".format(path))
            ctx.actions.symlink(
                output = s,
                target_file = f
            )
            sources.append(s)
        substitutions["%s" % info.label] = "file://{}".format(info.root)
    return substitutions, sources

def _helm_chart_impl(ctx):
    chart = ctx.actions.declare_file("out.yaml")
    binary = ctx.toolchains["@com_github_cmser_rules_helm//toolchain:toolchain_type"].HelmInfo.bin

    entry_point = ctx.actions.declare_file(ctx.file.entry_point.basename)
    subs, dep_sources = _compute_substitutions(ctx)

    ctx.actions.expand_template(
        output = entry_point,
        template = ctx.file.entry_point,
        substitutions = subs
    )

    exec = _write_exec(ctx, chart, entry_point)

    sources = []

    for f in ctx.files.srcs:
        src = ctx.actions.declare_file(f.path.replace(ctx.label.package + "/", ""))
        ctx.actions.symlink(
            output = src,
            target_file = f,
        )
        sources.append(src)

    ctx.actions.run(
        inputs = sources + [exec, entry_point] + dep_sources,
        outputs = [chart],
        executable = exec,
        tools = [binary],
    )
    return [
        HelmChartInfo(
            name = ctx.label.package,
            sources = depset(sources)
        ),
        DefaultInfo(
            files = depset([chart]),
            executable = exec
        )
    ]

helm_chart = rule(
    implementation = _helm_chart_impl,
    toolchains = ["@com_github_cmser_rules_helm//toolchain:toolchain_type"],
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "entry_point": attr.label(allow_single_file = True, mandatory = True),
        "deps": attr.label_list(providers = [HelmChartInfo]),
    }
)

def _helm_library_impl(ctx):
    srcs = []
    root = ""
    for f in ctx.files.srcs + [ctx.file.entry_point]:
        src = ctx.actions.declare_file(f.path.replace(ctx.label.workspace_root + "/" + ctx.label.package + "/", ""))
        ctx.actions.symlink(
            output = src,
            target_file = f,
        )
        srcs.append(src)
        if src.basename == "Chart.yaml":
            root = src.dirname
    return [
        HelmChartInfo(
            name = ctx.label.package,
            sources = depset(srcs),
            root = root,
            label = ctx.label
        ),
    ]

helm_library = rule(
    implementation = _helm_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = [HelmChartInfo]),
        "entry_point": attr.label(allow_single_file = True, mandatory = True),
    }
)

