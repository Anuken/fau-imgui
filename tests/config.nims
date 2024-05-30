switch("path", "$projectDir/../src")
#TODO: change to actual proper path...
--path:"../../Infernae/fau/src"

switch("gcc.linkerexe", "g++")

when defined(Windows):
  --l:"-static"

  switch("passL", "-static-libstdc++ -static-libgcc")