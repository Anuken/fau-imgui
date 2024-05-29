# Package

version     = "1.84.2"
author      = "Leonardo Mariscal"
description = "ImGui bindings for Nim"
license     = "MIT"
srcDir      = "src"
skipDirs    = @["tests"]

# Dependencies

requires "nim >= 1.0.0" # 1.0.0 promises that it will have backward compatibility

task gen, "Generate bindings from source":
  exec("nim r tools/generator.nim")

task test, "Create window with imgui demo":
  exec("nim r -d:cimguiStaticCgcc tests/test.nim") # requires cimgui.dll
  #exec("nim cpp -r tests/test.nim")

task ci, "Create window with imgui null demo":
  exec("nim r tests/tnull.nim") # requires cimgui.dll
  exec("nim cpp -r tests/tnull.nim")
