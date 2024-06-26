import core, fau/assets, os
import ../imgui

#https://github.com/ocornut/imgui/blob/master/backends/imgui_impl_glfw.cpp

converter toImVec2(vec: Vec2): ImVec2 = cast[ImVec2](vec)
converter toFauVec2(vec: ImVec2): Vec2 = cast[Vec2](vec)

const uiScaleFactor = 1f

type IVert = object
  pos: Vec2
  uv: Vec2
  color: Color

var
  fontTexture: Texture
  mesh: Mesh[IVert]
  shader: Shader
  cursors: array[ImGuiMouseCursor.high.int + 1, Cursor]
  initialized = false

proc mapKey(key: KeyCode): ImGuiKey =
  #TODO: number and numpad keys?
  return case key:
  of keyA: ImGuiKey.A
  of keyB: ImGuiKey.B
  of keyC: ImGuiKey.C
  of keyD: ImGuiKey.D
  of keyE: ImGuiKey.E
  of keyF: ImGuiKey.F
  of keyG: ImGuiKey.G
  of keyH: ImGuiKey.H
  of keyI: ImGuiKey.I
  of keyJ: ImGuiKey.J
  of keyK: ImGuiKey.K
  of keyL: ImGuiKey.L
  of keyM: ImGuiKey.M
  of keyN: ImGuiKey.N
  of keyO: ImGuiKey.O
  of keyP: ImGuiKey.P
  of keyQ: ImGuiKey.Q
  of keyR: ImGuiKey.R
  of keyS: ImGuiKey.S
  of keyT: ImGuiKey.T
  of keyU: ImGuiKey.U
  of keyV: ImGuiKey.V
  of keyW: ImGuiKey.W
  of keyX: ImGuiKey.X
  of keyY: ImGuiKey.Y
  of keyZ: ImGuiKey.Z
  of keyTab: ImGuiKey.Tab
  of keyLeft: ImGuiKey.LeftArrow
  of keyRight: ImGuiKey.RightArrow
  of keyUp: ImGuiKey.UpArrow
  of keyDown: ImGuiKey.DownArrow
  of keyPageUp: ImGuiKey.PageUp
  of keyPageDown: ImGuiKey.PageDown
  of keyHome: ImGuiKey.Home
  of keyEnd: ImGuiKey.End
  of keyInsert: ImGuiKey.Insert
  of keyDelete: ImGuiKey.Delete
  of keyBackspace: ImGuiKey.Backspace
  of keySpace: ImGuiKey.Space
  of keyReturn: ImGuiKey.Enter
  of keyEscape: ImGuiKey.Escape
  of keyLCtrl: ImGuiKey.LeftCtrl
  of keyLShift: ImGuiKey.LeftShift
  of keyLalt: ImGuiKey.LeftAlt
  of keyLsuper: ImGuiKey.LeftSuper
  of keyRCtrl: ImGuiKey.RightCtrl
  of keyRshift: ImGuiKey.RightShift
  of keyRalt: ImGuiKey.RightAlt
  of keyRsuper: ImGuiKey.RightSuper
  of keyApostrophe: ImGuiKey.Apostrophe
  of keyComma: ImGuiKey.Comma
  of keyMinus: ImGuiKey.Minus
  of keyPeriod: ImGuiKey.Period
  of keySlash: ImGuiKey.Slash
  of keySemicolon: ImGuiKey.Semicolon
  of keyEquals: ImGuiKey.Equal
  of keyLeftBracket: ImGuiKey.LeftBracket
  of keyBackSlash: ImGuiKey.Backslash
  of keyRightBracket: ImGuiKey.RightBracket
  of keyGrave: ImGuiKey.GraveAccent
  of keyCapsLock: ImGuiKey.CapsLock
  of keyScrollLock: ImGuiKey.ScrollLock
  of keyNumlockclear: ImGuiKey.NumLock
  of keyPrintScreen: ImGuiKey.PrintScreen
  of keyPause: ImGuiKey.Pause
  of keyF1: ImGuiKey.F1
  of keyF2: ImGuiKey.F2
  of keyF3: ImGuiKey.F3
  of keyF4: ImGuiKey.F4
  of keyF5: ImGuiKey.F5
  of keyF6: ImGuiKey.F6
  of keyF7: ImGuiKey.F7
  of keyF8: ImGuiKey.F8
  of keyF9: ImGuiKey.F9
  of keyF10: ImGuiKey.F10
  of keyF11: ImGuiKey.F11
  of keyF12: ImGuiKey.F12
  else: ImGuiKey.None

proc igGlfwGetClipboardText(userData: pointer): cstring {.cdecl.} =
  getClipboardString().cstring

proc igGlfwSetClipboardText(userData: pointer, text: cstring): void {.cdecl.} =
  setClipboardString($text)

proc createRenderer() =
  let io = igGetIO()
  var 
    pixels: ptr uint8
    width: int32
    height: int32

  when false: #just for testing fonts...
    const testFontData = staticRead("../src/imgui/cimgui/imgui/misc/fonts/Roboto-Medium.ttf")
    let fontData = testFontData

    io.fonts.clear()
    let font = io.fonts.addFontFromMemoryTTF(addr fontData[0], fontData.len.int32, 20f);
    io.fonts.build()
  
  io.fonts.getTexDataAsRGBA32(pixels.addr, width.addr, height.addr)
  fontTexture = loadTexturePtr(vec2i(width, height), pixels, filter = tfLinear)
  io.fonts.texID = fontTexture.addr

  #this is basically the spritebatch shader without mixcol
  shader = newShader(
    """
    attribute vec4 a_pos;
    attribute vec4 a_color;
    attribute vec2 a_uv;

    uniform mat4 u_proj;
    varying vec4 v_color;
    varying vec2 v_uv;

    void main(){
      v_color = a_color;
      v_uv = a_uv;
      gl_Position = u_proj * a_pos;
    }
    """,
    """
    varying lowp vec4 v_color;
    varying vec2 v_uv;
    uniform sampler2D u_texture;

    void main(){
      gl_FragColor = texture2D(u_texture, v_uv) * v_color;
    }
    """
  )

  mesh = newMesh[IVert](update = false, indexed = true)

proc imguiUpdateFau =
  let io = igGetIO()

  io.displaySize = fau.size / uiScaleFactor
  io.displayFramebufferScale = vec2(uiScaleFactor)

  io.deltaTime = fau.rawDelta.float32

  io.addKeyEvent(Ctrl, keyLCtrl.down or keyRCtrl.down)
  io.addKeyEvent(Shift, keyLShift.down or keyRShift.down)
  io.addKeyEvent(Alt, keyLAlt.down or keyRAlt.down)
  io.addKeyEvent(Super, keyLsuper.down or keyRsuper.down)

  io.addMousePosEvent(fau.mouse.x/uiScaleFactor, (fau.size.y - 1f - fau.mouse.y)/uiScaleFactor)

  let cursor = igGetMouseCursor()
  if cursor == ImGuiMouseCursor.None or io.mouseDrawCursor:
    setCursorHidden(true)
  else:
    setCursor(cursors[cursor.int])
    setCursorHidden(false)

  igNewFrame()

proc imguiRenderFau* =
  #pending fau draw operations need to be flushed
  drawFlush()

  #does this need to be called multiple times...? should it be moved out?
  igRender()

  let 
    io = igGetIO()
    data = igGetDrawData()

  data.scaleClipRects(io.displayFramebufferScale)

  let 
    #It's flipped and I don't know why.
    matrix = ortho(data.displayPos + vec2(0f, data.displaySize.y), data.displaySize * vec2(1f, -1f))
    pos = data.displayPos

  for n in 0..<data.cmdListsCount:
    var commands = data.cmdLists.data[n]
    var indexBufferOffset: int = 0

    mesh.updateData(
      0..commands.vtxBuffer.size.int,
      0..commands.idxBuffer.size.int,
      vertexPtr = commands.vtxBuffer.data[0].addr, 
      indexPtr = commands.idxBuffer.data[0].addr
    )

    for commandIndex in 0..<commands.cmdBuffer.size:
      var pcmd = commands.cmdBuffer.data[commandIndex]

      if pcmd.userCallback != nil:
        pcmd.userCallback(commands, pcmd.addr)
      else:
        var clipRect = rect(pcmd.clipRect.x - pos.x, pcmd.clipRect.y - pos.y, pcmd.clipRect.z - pcmd.clipRect.x - pos.x, pcmd.clipRect.w - pcmd.clipRect.y - pos.y)

        clipRect.y = (fau.size.y - clipRect.y) - clipRect.h

        if (clipRect.x < fau.size.x and clipRect.y < fau.size.y and clipRect.w > 0f and clipRect.h > 0f):
       
          mesh.render(shader, meshParams(
              clip = rect(clipRect.x, clipRect.y, clipRect.w, clipRect.h),
              offset = indexBufferOffset,
              count = pcmd.elemCount.int,
              blend = blendNormal
            )):
            proj = matrix
            #should use pcmd.textureId, but I only supplied one texture so I will use that for now
            texture = fontTexture.sampler(7)
        
        indexBufferOffset += pcmd.elemCount.int

proc imguiInitFau*(appName: string = "") =
  if initialized: return

  initialized = true

  let context = igCreateContext()
  let io = igGetIO()

  io.backendFlags = (io.backendFlags.int32 or ImGuiBackendFlags.HasMouseCursors.int32).ImGuiBackendFlags
  if appName == "":
    io.iniFilename = nil
  else:
    let folder = getSaveDir(appName)

    try:
      folder.createDir()
      io.iniFilename = folder / "imgui.ini"
    except:
      echo "Failed to create save directory: ", getCurrentExceptionMsg()
      io.iniFilename = nil

  cursors[ImGuiMouseCursor.Arrow.int] = newCursor(cursorArrow)
  cursors[ImGuiMouseCursor.TextInput.int] = newCursor(cursorIbeam)
  cursors[ImGuiMouseCursor.ResizeNS.int] = newCursor(cursorResizeV)
  cursors[ImGuiMouseCursor.ResizeEW.int] = newCursor(cursorResizeH)
  cursors[ImGuiMouseCursor.Hand.int] = newCursor(cursorHand)
  cursors[ImGuiMouseCursor.ResizeAll.int] = newCursor(cursorResizeAll)
  cursors[ImGuiMouseCursor.ResizeNESW.int] = newCursor(cursorResizeNesw)
  cursors[ImGuiMouseCursor.ResizeNWSE.int] = newCursor(cursorResizeNwse)
  cursors[ImGuiMouseCursor.NotAllowed.int] = newCursor(cursorNotAllowed)

  createRenderer()

  io.setClipboardTextFn = igGlfwSetClipboardText
  io.getClipboardTextFn = igGlfwGetClipboardText

  addFauListener do(e: FauEvent):
    case e.kind:
    of feFrame:
      imguiUpdateFau()
    of feEndFrame:
      imguiRenderFau()
    of feDestroy:
      context.igDestroyContext()
      initialized = false
    of feKey:
      let mapped = mapKey(e.key)
      if mapped != ImGuiKey.None:
        io.addKeyEvent(mapped, e.keyDown)
    of feText:
      io.addInputCharacter(e.text)
    of feTouch:
      if e.touchButton in {keyMouseLeft, keyMouseRight, keyMouseMiddle}:
        let code = case e.touchButton:
        of keyMouseLeft: ImGuiMouseButton.Left
        of keyMouseRight: ImGuiMouseButton.Right
        of keyMouseMiddle: ImGuiMouseButton.Middle
        else: ImGuiMouseButton.Left

        io.addMouseButtonEvent(code.int32, e.touchDown)
    of feScroll:
      io.addMouseWheelEvent(e.scroll.x, e.scroll.y)
    else: discard
