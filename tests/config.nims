switch("path", "$projectDir/../src")
#TODO: change to actual proper path...
--path:"../../Infernae/fau/src"

when defined(MacOSX):
  switch("clang.linkerexe", "g++")
else:
  switch("gcc.linkerexe", "g++")

when defined(Windows):
  --l:"-static"

  switch("passL", "-static-libstdc++ -static-libgcc")