#!/usr/bin/python

import yampl
import signal

signal.signal(signal.SIGINT, signal.SIG_DFL)

s = yampl.ServerSocket("service", "local_pipe")
size, buf = s.recv()
s.send("hello world!")
print(buf)
