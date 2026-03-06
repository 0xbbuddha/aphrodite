import std/[osproc, os]

proc runShell*(params: string, cwd: string): string =
  if params.len == 0:
    return "Error: no command provided"
  let workDir = if cwd.len > 0: cwd else: getCurrentDir()
  try:
    when defined(windows):
      let (output, _) = execCmdEx(
        "cmd.exe /c " & params,
        options = {poStdErrToStdOut},
        workingDir = workDir,
      )
    else:
      let (output, _) = execCmdEx(
        "/bin/sh -c " & quoteShell(params),
        options = {poStdErrToStdOut},
        workingDir = workDir,
      )
    result = output
  except Exception as e:
    result = "Error: " & e.msg
