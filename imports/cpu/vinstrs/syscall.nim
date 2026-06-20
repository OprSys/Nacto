import std/terminal
import std/strutils
import std/sequtils

import process/procapi as ProcApi
import cpu/vinstr_registry

const SYSC_PRINT* = 1
const SYSC_READCHR* = 2
const SYSC_OPENFILE* = 3
const SYSC_CREATEFILE* = 4
const SYSC_WRITEFILE* = 5
const SYSC_READFILE* = 6
const SYSC_CLOSEFD* = 7

import cpu/errors/all as BINERRC
import fs/errors/all as FSERRC
import cpu/types/limits as LIMITS
import cpu/types/ascii as ASCII
import fs/fsapi as FsApi
import hardware/disk as NactoDisk

proc LRAMGET(len: int, highslot: int, procobj: ProcApi.ProcTypes.ProcessObject): string =
    if len < 0 or len >= ProcApi.ProcTypes.LOW:
        raise newException(BINERRC.OutOfBounds, $len & " is not in the range of 0 to " & $(ProcApi.ProcTypes.LOW - 1))

    var ret = ""
    for i in 0..<len:
        ret.add(ASCII.ToChar(procobj.ProcessState.LRAM[highslot][i]))
    
    return ret

proc LRAMGETSECT(highslot: int, lowslot: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    if highslot < 0 or highslot >= ProcApi.ProcTypes.HIGH:
        raise newException(BINERRC.OutOfBounds, $highslot & " is not in the range of 0 to " & $(ProcApi.ProcTypes.HIGH - 1))
    if lowslot < 0 or lowslot >= ProcApi.ProcTypes.LOW:
        raise newException(BINERRC.OutOfBounds, $lowslot & " is not in the range of 0 to " & $(ProcApi.ProcTypes.LOW - 1))
    return procobj.ProcessState.LRAM[highslot][lowslot]

proc GETENTRYBYFD(fd: int, procobj: ProcApi.ProcTypes.ProcessObject): ProcApi.ProcTypes.OpenFileEntry =
    return procobj.ProcessState.FileDescriptors[fd]

proc PRINT(highslot: int, lowslot: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    let val = procobj.ProcessState.LRAM[highslot][lowslot]
    let character = ASCII.ToChar(val)
    stdout.write(character)
    return 0

proc READCHR(highslot: int, lowslot: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    let rawcharacter = terminal.getch()
    let character = ASCII.ToCode(rawcharacter)
    procobj.ProcessState.LRAM[highslot][lowslot] = character
    return 0

proc OPENFILE(len: int, highslot: int, fdto: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    let path = LRAMGET(len, highslot, procobj)

    let resolved = FsApi.ResolvePath(path)

    if resolved == nil:
        raise newException(FSERRC.NoPath, "requested CoreDataObject not found \"" & path & "\"")
    
    if resolved of NactoDisk.DiskTypes.Directory:
        raise newException(FSERRC.InvalidCDOType, "requested CoreDataObject is of a Directory, but was expected to be a File")

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
            raise newException(BINERRC.InvalidIndex, "[" & $idx & "][" & $file.Data.len & "] is not a valid index")
        if idx == file.Data.len:
            file.Data.add(character)
        else:
            file.Data[idx] = character
    else:
        raise newException(BINERRC.InvalidIndex, "requested OpenFileEntry (using file descriptor) does not exist \"" & $fd & "\"")
    return 0

proc READFILE(highslot: int, lowslot: int, fd: int, idx: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    if fd < procobj.ProcessState.FileDescriptors.len and procobj.ProcessState.FileDescriptors[fd] != nil:
        let file = procobj.ProcessState.FileDescriptors[fd].File
        if idx < 0 or idx >= file.Data.len:
            raise newException(BINERRC.InvalidIndex, "[" & $idx & "][" & $file.Data.len & "] is not a valid index")
        let character = ASCII.ToCode(file.Data[idx])
        procobj.ProcessState.LRAM[highslot][lowslot] = character
    else:
        raise newException(BINERRC.InvalidIndex, "requested OpenFileEntry (using file descriptor) does not exist \"" & $fd & "\"")
    return 0

proc CLOSEFD(fd: int, procobj: ProcApi.ProcTypes.ProcessObject): int =
    if fd < procobj.ProcessState.FileDescriptors.len and procobj.ProcessState.FileDescriptors[fd] != nil:
        procobj.ProcessState.FileDescriptors[fd] = nil
    else:
        raise newException(BINERRC.InvalidIndex, "requested OpenFileEntry (using file descriptor) does not exist \"" & $fd & "\"")
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
    else:
        discard
    return 0

register("SYSCALL", execute)