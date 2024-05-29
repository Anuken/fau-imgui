switch("path", "$projectDir/../src")
--path:"../../Infernae/fau/src"

switch("gcc.linkerexe", "g++")

when defined(Windows):
  #TODO does this work? needed for tlsEmulation:off
  --l:"-static"

  switch("passL", "-static-libstdc++ -static-libgcc")