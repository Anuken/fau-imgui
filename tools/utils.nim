# Written by Leonardo Mariscal <leo@ldmd.mx>, 2019

const srcHeader* = """

## Originally Written by Leonardo Mariscal <leo@ldmd.mx>, 2019
## 
## Updated to ImGUI 1.90.7 with the help of code from <https://github.com/nimgl/imgui/pull/10>
## 
## ImGUI Bindings
## ====
## WARNING: This is a generated file. Do not edit.
## Any edits will be overwritten by the generator.
##
## The aim is to achieve as much compatibility with C as possible.
##
## You can check the original documentation `here <https://github.com/ocornut/imgui/blob/master/imgui.cpp>`_.
##

import std/[compilesettings, strformat, strutils, os]

## Tentative workaround [start]
type
  uint32Ptr* = ptr uint32
  ImguiDockRequest* = distinct object
  ImGuiDockNodeSettings* = distinct object
  const_cstringPtr* {.pure, inheritable, bycopy.} = object
    Size*: cint
    Capacity*: cint
    Data*: ptr ptr cschar

## Tentative workaround [end]

const
  nimcache = querySetting(SingleValueSetting.nimcacheDir)

proc currentSourceDir(): string {.compileTime.} =
  result = currentSourcePath().replace("\\", "/")
  result = result[0 ..< result.rfind("/")]

{.passC: "-I" & currentSourceDir() & "/imgui/cimgui" & " -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1".}

template compileCpp(file: string, name: string) =
  const objectPath = nimcache & "/" & name & ".cpp.o"

  static:
    if not fileExists(objectPath):
      createDir(objectPath.parentDir)
      echo staticExec("g++ -std=c++14 -c -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1 imgui/cimgui/" & file & " -o " & objectPath)

  {.passL: objectPath.}

compileCpp("cimgui.cpp", "cimgui.cpp")
compileCpp("imgui/imgui.cpp", "imgui.cpp")
compileCpp("imgui/imgui_draw.cpp", "imgui_draw.cpp")
compileCpp("imgui/imgui_tables.cpp", "imgui_tables.cpp")
compileCpp("imgui/imgui_widgets.cpp", "imgui_widgets.cpp")
compileCpp("imgui/imgui_demo.cpp", "imgui_demo.cpp")

{.passc: "-DCIMGUI_DEFINE_ENUMS_AND_STRUCTS".}
{.pragma: imgui_header, header: "cimgui.h".}
"""

const notDefinedStructs* = """
  ImVector*[T] = object # Should I importc a generic?
    size* {.importc: "Size".}: int32
    capacity* {.importc: "Capacity".}: int32
    data* {.importc: "Data".}: ptr UncheckedArray[T]
  ImGuiStyleModBackup* {.union.} = object
    backup_int* {.importc: "BackupInt".}: int32 # Breaking naming convetion to denote "low level"
    backup_float* {.importc: "BackupFloat".}: float32
  ImGuiStyleMod* {.importc: "ImGuiStyleMod", imgui_header.} = object
    varIdx* {.importc: "VarIdx".}: ImGuiStyleVar
    backup*: ImGuiStyleModBackup
  ImGuiStoragePairData* {.union.} = object
    val_i* {.importc: "val_i".}: int32 # Breaking naming convetion to denote "low level"
    val_f* {.importc: "val_f".}: float32
    val_p* {.importc: "val_p".}: pointer
  ImGuiStoragePair* {.importc: "ImGuiStoragePair", imgui_header.} = object
    key* {.importc: "key".}: ImGuiID
    data*: ImGuiStoragePairData
  ImPairData* {.union.} = object
    val_i* {.importc: "val_i".}: int32 # Breaking naming convetion to denote "low level"
    val_f* {.importc: "val_f".}: float32
    val_p* {.importc: "val_p".}: pointer
  ImPair* {.importc: "Pair", imgui_header.} = object
    key* {.importc: "key".}: ImGuiID
    data*: ImPairData
  ImGuiInputEventData* {.union.} = object
    mousePos*: ImGuiInputEventMousePos
    mouseWheel*: ImGuiInputEventMouseWheel
    mouseButton*: ImGuiInputEventMouseButton
    key*: ImGuiInputEventKey
    text*: ImGuiInputEventText
    appFocused*: ImGuiInputEventAppFocused
  ImGuiInputEvent* {.importc: "ImGuiInputEvent", imgui_header.} = object
    `type`* {.importc: "`type`".}: ImGuiInputEventType
    source* {.importc: "Source".}: ImGuiInputSource
    data*: ImGuiInputEventData
    addedByTestEngine* {.importc: "AddedByTestEngine".}: bool

  # Undefined data types in cimgui

  ImDrawListPtr* = object
  ImChunkStream* = ptr object
  ImPool* = object
  ImSpanAllocator* = object # A little lost here. It is referenced in imgui_internal.h
  ImSpan* = object # ^^
  ImVectorImGuiColumns* {.importc: "ImVector_ImGuiColumns".} = object

  #
"""

const preProcs* = """
# Procs
{.push warning[HoleEnumConv]: off.}
{.push nodecl, discardable,header: currentSourceDir() & "/imgui/cimgui/cimgui.h".}
"""

const postProcs* = """
{.pop.} # push dynlib / nodecl, etc...
{.pop.} # push warning[HoleEnumConv]: off
"""

let reservedWordsDictionary* = [
"end", "type", "out", "in", "ptr", "ref"
]

let blackListProc* = [ "" ]

const cherryTheme* = """
proc igStyleColorsCherry*(dst: ptr ImGuiStyle = nil): void =
  ## To conmemorate this bindings this style is included as a default.
  ## Style created originally by r-lyeh
  var style = igGetStyle()
  if dst != nil:
    style = dst

  const ImVec4 = proc(x: float32, y: float32, z: float32, w: float32): ImVec4 = ImVec4(x: x, y: y, z: z, w: w)
  const igHI = proc(v: float32): ImVec4 = ImVec4(0.502f, 0.075f, 0.256f, v)
  const igMED = proc(v: float32): ImVec4 = ImVec4(0.455f, 0.198f, 0.301f, v)
  const igLOW = proc(v: float32): ImVec4 = ImVec4(0.232f, 0.201f, 0.271f, v)
  const igBG = proc(v: float32): ImVec4 = ImVec4(0.200f, 0.220f, 0.270f, v)
  const igTEXT = proc(v: float32): ImVec4 = ImVec4(0.860f, 0.930f, 0.890f, v)

  style.colors[ImGuiCol.Text.int32]                 = igTEXT(0.88f)
  style.colors[ImGuiCol.TextDisabled.int32]         = igTEXT(0.28f)
  style.colors[ImGuiCol.WindowBg.int32]             = ImVec4(0.13f, 0.14f, 0.17f, 1.00f)
  style.colors[ImGuiCol.PopupBg.int32]              = igBG(0.9f)
  style.colors[ImGuiCol.Border.int32]               = ImVec4(0.31f, 0.31f, 1.00f, 0.00f)
  style.colors[ImGuiCol.BorderShadow.int32]         = ImVec4(0.00f, 0.00f, 0.00f, 0.00f)
  style.colors[ImGuiCol.FrameBg.int32]              = igBG(1.00f)
  style.colors[ImGuiCol.FrameBgHovered.int32]       = igMED(0.78f)
  style.colors[ImGuiCol.FrameBgActive.int32]        = igMED(1.00f)
  style.colors[ImGuiCol.TitleBg.int32]              = igLOW(1.00f)
  style.colors[ImGuiCol.TitleBgActive.int32]        = igHI(1.00f)
  style.colors[ImGuiCol.TitleBgCollapsed.int32]     = igBG(0.75f)
  style.colors[ImGuiCol.MenuBarBg.int32]            = igBG(0.47f)
  style.colors[ImGuiCol.ScrollbarBg.int32]          = igBG(1.00f)
  style.colors[ImGuiCol.ScrollbarGrab.int32]        = ImVec4(0.09f, 0.15f, 0.16f, 1.00f)
  style.colors[ImGuiCol.ScrollbarGrabHovered.int32] = igMED(0.78f)
  style.colors[ImGuiCol.ScrollbarGrabActive.int32]  = igMED(1.00f)
  style.colors[ImGuiCol.CheckMark.int32]            = ImVec4(0.71f, 0.22f, 0.27f, 1.00f)
  style.colors[ImGuiCol.SliderGrab.int32]           = ImVec4(0.47f, 0.77f, 0.83f, 0.14f)
  style.colors[ImGuiCol.SliderGrabActive.int32]     = ImVec4(0.71f, 0.22f, 0.27f, 1.00f)
  style.colors[ImGuiCol.Button.int32]               = ImVec4(0.47f, 0.77f, 0.83f, 0.14f)
  style.colors[ImGuiCol.ButtonHovered.int32]        = igMED(0.86f)
  style.colors[ImGuiCol.ButtonActive.int32]         = igMED(1.00f)
  style.colors[ImGuiCol.Header.int32]               = igMED(0.76f)
  style.colors[ImGuiCol.HeaderHovered.int32]        = igMED(0.86f)
  style.colors[ImGuiCol.HeaderActive.int32]         = igHI(1.00f)
  style.colors[ImGuiCol.ResizeGrip.int32]           = ImVec4(0.47f, 0.77f, 0.83f, 0.04f)
  style.colors[ImGuiCol.ResizeGripHovered.int32]    = igMED(0.78f)
  style.colors[ImGuiCol.ResizeGripActive.int32]     = igMED(1.00f)
  style.colors[ImGuiCol.PlotLines.int32]            = igTEXT(0.63f)
  style.colors[ImGuiCol.PlotLinesHovered.int32]     = igMED(1.00f)
  style.colors[ImGuiCol.PlotHistogram.int32]        = igTEXT(0.63f)
  style.colors[ImGuiCol.PlotHistogramHovered.int32] = igMED(1.00f)
  style.colors[ImGuiCol.TextSelectedBg.int32]       = igMED(0.43f)

  style.windowPadding     = ImVec2(x: 6f, y: 4f)
  style.windowRounding    = 0.0f
  style.framePadding      = ImVec2(x: 5f, y: 2f)
  style.frameRounding     = 3.0f
  style.itemSpacing       = ImVec2(x: 7f, y: 1f)
  style.itemInnerSpacing  = ImVec2(x: 1f, y: 1f)
  style.touchExtraPadding = ImVec2(x: 0f, y: 0f)
  style.indentSpacing     = 6.0f
  style.scrollbarSize     = 12.0f
  style.scrollbarRounding = 16.0f
  style.grabMinSize       = 20.0f
  style.grabRounding      = 2.0f

  style.windowTitleAlign.x = 0.50f

  style.colors[ImGuiCol.Border.int32] = ImVec4(0.539f, 0.479f, 0.255f, 0.162f)
  style.frameBorderSize  = 0.0f
  style.windowBorderSize = 1.0f

  style.displaySafeAreaPadding.y = 0
  style.framePadding.y = 1
  style.itemSpacing.y = 1
  style.windowPadding.y = 3
  style.scrollbarSize = 13
  style.frameBorderSize = 1
  style.tabBorderSize = 1
"""