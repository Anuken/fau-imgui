import core
import ../imgui

proc imguiInitFau* =
  let context = igCreateContext()
  let io = igGetIO()

proc imguiUpdateFau* =

  igNewFrame()

proc imguiRenderFau* =
  discard