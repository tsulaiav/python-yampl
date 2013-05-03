import subprocess
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

yampl_include = subprocess.check_output(["pkg-config", "yampl", "--cflags"]).decode("utf-8")[2:-2]
yampl_libs = subprocess.check_output(["pkg-config", "yampl", "--libs"]).decode("utf-8")[:-2]

setup(
  name = "yampl",
  version = "1.0",
  ext_modules=[ 
    Extension("yampl", 
              sources=["yampl.pyx"],
              libraries=["yampl"],
              include_dirs=[yampl_include],
              extra_link_args=[yampl_libs],
              language="c++"),
    ],
  cmdclass = {"build_ext": build_ext},

)
