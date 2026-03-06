proc runPwd*(cwd: string): string =
  result = if cwd.len > 0: cwd else: "unknown"
