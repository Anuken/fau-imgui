# Written by Leonardo Mariscal <leo@ldmd.mx>, 2019

import os, strutils, streams, json, strformat,
       tables, algorithm, sets, ./utils

var enums: HashSet[string]
var enumsCount: Table[string, int]

proc uncapitalize(s: string): string =
  if s.len < 1:
    result = ""
  else:
    result = toLowerAscii(s[0]) & s[1 ..< s.len]

proc translateProc(name: string): string =
  "int32"

proc translateType(name: string): string =
  if name.contains("(") and name.contains(")"):
    return name.translateProc()

  result = name.replace("const ", "")
  result = result.replace("unsigned ", "u")
  result = result.replace("signed ", "")
  result = result.replace("int", "int32")
  result = result.replace("int3264_t", "int64")
  result = result.replace("float", "float32")
  result = result.replace("double", "float64")
  result = result.replace("short", "int16")
  if not name.contains("Wchar"):
    result = result.replace("char", "int8")
  result = result.replace("void*", "pointer")

  result = result.replace("ImS8", "int8") # Doing it a little verbose to avoid issues in the future.
  result = result.replace("ImS16", "int16")
  result = result.replace("ImS32", "int32")
  result = result.replace("ImS64", "int64")
  result = result.replace("ImU8", "uint8")
  result = result.replace("ImU16", "uint16")
  result = result.replace("ImU32", "uint32")
  result = result.replace("ImU64", "uint64")
  result = result.replace("Pair", "ImPair")

  if not result.contains('*'):
    return

  let depth = result.count('*')
  result = result.replace(" ", "")
  result = result.replace("*", "")
  for d in 0 ..< depth:
    result = "ptr " & result

proc genEnums(output: var string) =
  let file = readFile("src/imgui/private/cimgui/generator/output/structs_and_enums.json")
  let data = file.parseJson()

  output.add("\n# Enums\ntype\n")

  for name, obj in data["enums"].pairs:
    let enumName = name[0 ..< name.len - 1]
    output.add("  {enumName}* {{.pure, size: int32.sizeof.}} = enum\n".fmt)
    enums.incl(enumName)
    var table: OrderedTable[int, string]
    for data in obj:
      var dataName = data["name"].getStr()
      dataName = dataName.replace("__", "_")
      dataName = dataName.split("_")[1]
      if dataName.endsWith("_"):
        dataName = dataName[0 ..< dataName.len - 1]
      if dataName == "COUNT":
        enumsCount[data["name"].getStr()] = data["calc_value"].getInt()
        continue
      let dataValue = data["calc_value"].getInt()
      if table.hasKey(dataValue):
        echo "Enum {enumName}.{dataName} already exists as {enumName}.{table[dataValue]} with value {dataValue} skipping...".fmt
        continue
      table[dataValue] = dataName
    table.sort(system.cmp)
    for k, v in table.pairs:
      output.add("    {v} = {k}\n".fmt)

proc genTypeDefs(output: var string) =
  # This must run after genEnums
  let file = readFile("src/imgui/private/cimgui/generator/output/typedefs_dict.json")
  let data = file.parseJson()

  output.add("\n# TypeDefs\ntype\n")

  for name, obj in data.pairs:
    let ignorable = ["const_iterator", "iterator", "value_type", "ImS8",
                     "ImS16", "ImS32", "ImS64", "ImU8", "ImU16", "ImU32",
                     "ImU64"]
    if obj.getStr().startsWith("struct") or enums.contains(name) or ignorable.contains(name):
      continue
    output.add("  {name}* = {obj.getStr().translateType()}\n".fmt)

proc genTypes(output: var string) =
  # This must run after genEnums
  let file = readFile("src/imgui/private/cimgui/generator/output/structs_and_enums.json")
  let data = file.parseJson()

  output.add("\n# Types\ntype\n")
  output.add(notDefinedStructs)

  for name, obj in data["structs"].pairs:
    if name == "Pair":
      continue
    output.add("  {name}* {{.importc: \"{name}\", imgui_header.}} = object\n".fmt)
    for member in obj:
      var memberName = member["name"].getStr()
      if memberName.startsWith("_"):
        memberName = memberName[1 ..< memberName.len]
      memberName = memberName.uncapitalize()

      if not memberName.contains("["):
        if not member.contains("template_type"):
          output.add("    {memberName}*: {member[\"type\"].getStr().translateType()}\n".fmt)
        else:
          # Assuming all template_type containers are ImVectors
          output.add("    {memberName}*: ImVector[{member[\"template_type\"].getStr().translateType()}]\n".fmt)
        continue

      let memberNameSplit = memberName.rsplit('[', 1)
      var arraySize = memberNameSplit[1]
      arraySize = arraySize[0 ..< arraySize.len - 1]
      if arraySize.contains("COUNT"):
        arraySize = $enumsCount[arraySize]

      output.add("    {memberNameSplit[0]}*: array[{arraySize}, {member[\"type\"].getStr().translateType()}]\n".fmt)

proc igGenerate*() =
  var output = srcHeader

  output.genEnums()
  output.genTypeDefs()
  output.genTypes()

  #output.add("{.pop.}")
  writeFile("src/imgui.nim", output)

when isMainModule:
  igGenerate()
