COPY <<EOF /etc/sysctl.d/99-sick-ptrace-scope.conf
kernel.yama.ptrace_scope = 3
EOF