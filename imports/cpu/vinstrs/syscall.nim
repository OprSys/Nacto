import std/terminal
import std/strutils
import std/sequtils
when defined(linux):
    import posix

import process/procapi as ProcApi
import cpu/vinstr_registry

# I/O
const SYSC_PRINT* = 1
const SYSC_READCHR* = 2

# VFS
const SYSC_OPENFILE* = 3
const SYSC_CREATEFILE* = 4
const SYSC_WRITEFILE* = 5
const SYSC_READFILE* = 6
const SYSC_CLOSEFD* = 7

# Processes
const SYSC_SENDSIG* = 8
const SYSC_EXEC* = 9
const SYSC_WAITPID* = 10

import cpu/types/limits as LIMITS
import cpu/types/ascii as ASCII
import fs/fsapi as FsApi
import hardware/disk as NactoDisk
import process/executor as NactoExec
import process/procapi as ProcApi

import error/errorapi as ErrorApi
import helper/hasstdin

proc LRAMGET(len: int, highslot: int, procobj: ProcApi.ProcTypes.ProcessObject): string =
    if len < 0 or len >= ProcApi.ProcTypes.LOW:
        ErrorApi.ThrowError(ErrorApi.newerr("LRAMGET length out of bounds", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))

    var ret = ""
    for i in 0..<len:
        ret.add(ASCII.ToChar(procobj.ProcessState.LRAM[highslot][i]))
    
    return ret

proc LRAMGETSECT(highslot: int, lowslot: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    if highslot < 0 or highslot >= ProcApi.ProcTypes.HIGH:
        ErrorApi.ThrowError(ErrorApi.newerr("LRAM high slot out of bounds", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))
    if lowslot < 0 or lowslot >= ProcApi.ProcTypes.LOW:
        ErrorApi.ThrowError(ErrorApi.newerr("LRAM low slot out of bounds", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))
    return procobj.ProcessState.LRAM[highslot][lowslot]

proc GETENTRYBYFD(fd: int, procobj: ProcApi.ProcTypes.ProcessObject): ProcApi.ProcTypes.OpenFileEntry =
    return procobj.ProcessState.FileDescriptors[fd]

proc PRINT(highslot: int, lowslot: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    let val = procobj.ProcessState.LRAM[highslot][lowslot]
    let character = ASCII.ToChar(val)
    stdout.write(character)
    stdout.flushFile()
    return 0

proc READCHR(highslot: int, lowslot: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    if not hasstdin():
        procobj.ProcessState.Running = ProcApi.ProcTypes.IsRunningState.WaitingForInput
        return 0
    when defined(linux):
        var c: char
        discard read(0, addr(c), 1)
        let character = ASCII.ToCode(c)
    elif defined(windows):
        let rawcharacter = terminal.getch()
        let character = ASCII.ToCode(rawcharacter)
    procobj.ProcessState.LRAM[highslot][lowslot] = character
    return 0

proc OPENFILE(len: int, highslot: int, fdto: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    let path = LRAMGET(len, highslot, procobj)

    let resolved = FsApi.ResolvePath(path)

    if resolved == nil:
        ErrorApi.ThrowError(ErrorApi.newerr("file not found", ErrorApi.SysErr.ErrorSeverity.Error, ErrorApi.ErrTypes.CATEGORY_FS, ErrorApi.ErrTypes.FS_NOPATH))
    
    if resolved of NactoDisk.DiskTypes.Directory:
        ErrorApi.ThrowError(ErrorApi.newerr("cannot open a directory as a file", ErrorApi.SysErr.ErrorSeverity.Error, ErrorApi.ErrTypes.CATEGORY_FS, ErrorApi.ErrTypes.FS_INVCDO))

    var fileEntry = ProcApi.ProcTypes.OpenFileEntry()
    fileEntry.File = NactoDisk.DiskTypes.File(resolved)
    let idx = procobj.ProcessState.FileDescriptors.find(nil)
    if idx >= 0:
        procobj.ProcessState.FileDescriptors[idx] = fileEntry
        discard vinstr_registry.lookup("SETVAL")(@[$fdto, $idx], procobj)
    else:
        procobj.ProcessState.FileDescriptors.add(fileEntry)
        discard vinstr_registry.lookup("SETVAL")(@[$fdto, $(procobj.ProcessState.FileDescriptors.len-1)], procobj)
    discard vinstr_registry.lookup("SETVAL")(@[$fdto, $(procobj.ProcessState.FileDescriptors.len-1)], procobj)
    return 0

proc CREATEFILE(len: int, highslot: int, filetype: int, fdto: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    let path_name = LRAMGET(len, highslot, procobj)
    let name = path_name.split('/')[^1]
    let parentPath = if path_name.len > name.len:
        path_name[0..^(name.len + 1)]
      else:
        "/"
    let filetype_enm = NactoDisk.DiskTypes.FT.FileTypes(filetype)

    var file = FsApi.CreateFile(parentPath, name, filetype_enm)

    var fileEntry = ProcApi.ProcTypes.OpenFileEntry()
    fileEntry.File = file
    let idx = procobj.ProcessState.FileDescriptors.find(nil)
    if idx >= 0:
        procobj.ProcessState.FileDescriptors[idx] = fileEntry
        discard vinstr_registry.lookup("SETVAL")(@[$fdto, $idx], procobj)
    else:
        procobj.ProcessState.FileDescriptors.add(fileEntry)
        discard vinstr_registry.lookup("SETVAL")(@[$fdto, $(procobj.ProcessState.FileDescriptors.len-1)], procobj)
    return 0

proc WRITEFILE(highslot: int, lowslot: int, fd: int, idx: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    let code = LRAMGETSECT(highslot, lowslot, procobj)
    let character = ASCII.ToChar(code)
    if fd < procobj.ProcessState.FileDescriptors.len and procobj.ProcessState.FileDescriptors[fd] != nil:
        let file = procobj.ProcessState.FileDescriptors[fd].File
        if idx < 0 or idx > file.Data.len:
            ErrorApi.ThrowError(ErrorApi.newerr("file write index out of bounds", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_INVIDX))
        if idx == file.Data.len:
            file.Data.add(character)
        else:
            file.Data[idx] = character
    else:
        ErrorApi.ThrowError(ErrorApi.newerr("invalid file descriptor for write", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_INVIDX))
    return 0

proc READFILE(highslot: int, lowslot: int, fd: int, idx: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    if fd < procobj.ProcessState.FileDescriptors.len and procobj.ProcessState.FileDescriptors[fd] != nil:
        let file = procobj.ProcessState.FileDescriptors[fd].File
        if idx < 0 or idx >= file.Data.len:
            ErrorApi.ThrowError(ErrorApi.newerr("file read index out of bounds", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_INVIDX))
        let character = ASCII.ToCode(file.Data[idx])
        procobj.ProcessState.LRAM[highslot][lowslot] = character
    else:
        ErrorApi.ThrowError(ErrorApi.newerr("invalid file descriptor for read", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_INVIDX))
    return 0

proc CLOSEFD(fd: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    if fd < procobj.ProcessState.FileDescriptors.len and procobj.ProcessState.FileDescriptors[fd] != nil:
        procobj.ProcessState.FileDescriptors[fd] = nil
    else:
        ErrorApi.ThrowError(ErrorApi.newerr("invalid file descriptor for close", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_INVIDX))
    return 0

const signals: array[6, ProcApi.ProcTypes.Signal] = [
    ProcApi.ProcTypes.Signal(Name: "", Id: 0, CanBeOverridden: false),
    ProcApi.ProcTypes.SIG_FTERM,
    ProcApi.ProcTypes.SIG_TERM,
    ProcApi.ProcTypes.SIG_GEN1,
    ProcApi.ProcTypes.SIG_GEN2,
    ProcApi.ProcTypes.SIG_GEN3
]
proc SENDSIG(pid: int, signal: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    ProcApi.SendSignal(pid, signals[signal])
    return 0

proc EXEC(len: int, highslot: int, pidto: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    let path = LRAMGET(len, highslot, procobj)

    let obj = FsApi.ResolvePath(path)
    if obj == nil:
        ErrorApi.ThrowError(ErrorApi.newerr(
            "no such file or directory \"" & path & "\"",
            ErrorApi.SysErr.ErrorSeverity.Error,
            ErrorApi.ErrTypes.CATEGORY_FS,
            ErrorApi.ErrTypes.FS_NOPATH
        ))
    elif not (obj of NactoDisk.DiskTypes.File):
        ErrorApi.ThrowError(ErrorApi.newerr(
            "requested CoreDataObject is not a file",
            ErrorApi.SysErr.ErrorSeverity.Error,
            ErrorApi.ErrTypes.CATEGORY_FS,
            ErrorApi.ErrTypes.FS_INVCDO
        ))



    let pid = NactoExec.ExecuteBinaryAtPath(path)

    discard vinstr_registry.lookup("SETVAL")(@[$pidto, $pid], procobj)
    return 0

proc WAITPID(pid: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    if ProcApi.GetProcess(pid) == nil:
        return 0
    if pid == procobj.Id:
        return 0
    procobj.ProcessState.Running = ProcApi.ProcTypes.IsRunningState.WaitingForProcess
    procobj.ProcessState.WaitingFor = pid
    return 0

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let syscall_number = procobj.ProcessState.Vm[0]
    let arg1 = procobj.ProcessState.Vm[1]
    let arg2 = procobj.ProcessState.Vm[2]
    let arg3 = procobj.ProcessState.Vm[3]
    let arg4 = procobj.ProcessState.Vm[4]

    case syscall_number
    of SYSC_PRINT:
        return PRINT(arg1, arg2, procobj)
    of SYSC_READCHR:
        return READCHR(arg1, arg2, procobj)
    of SYSC_OPENFILE:
        return OPENFILE(arg1, arg2, arg3, procobj)
    of SYSC_CREATEFILE:
        return CREATEFILE(arg1, arg2, arg3, arg4, procobj)
    of SYSC_WRITEFILE:
        return WRITEFILE(arg1, arg2, arg3, arg4, procobj)
    of SYSC_READFILE:
        return READFILE(arg1, arg2, arg3, arg4, procobj)
    of SYSC_CLOSEFD:
        return CLOSEFD(arg1, procobj)
    of SYSC_SENDSIG:
        return SENDSIG(arg1, arg2, procobj)
    of SYSC_EXEC:
        return EXEC(arg1, arg2, arg3, procobj)
    of SYSC_WAITPID:
        return WAITPID(arg1, procobj)
    else:
        discard
    return 0

register("SYSCALL", execute)
