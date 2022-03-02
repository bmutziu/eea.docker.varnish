import os

with open("/etc/varnish/default.vcl", "r") as old_conf:
    with open("/etc/varnish/new_default.vcl", "w") as new_conf:
        linesold = [line for line in old_conf
                    if not line.startswith("#") and "v4.0" not in line and "include" not in line and not line == "\n" ]

        includes = os.listdir("/etc/varnish/conf.d")
        includes = ['include "/etc/varnish/conf.d/{name}";'.format(name=name)
                    for name in sorted(includes) if name.endswith('.vcl')]

        lines = "v4.0"
        lines.extend(includes)
        lines.extend(linesold)
        new_conf.write("\n".join(lines))

os.rename("/etc/varnish/new_default.vcl", "/etc/varnish/default.vcl")
