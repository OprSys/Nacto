import std/strutils

import process/procapi as ProcApi
import fs/fsapi as FsApi
import cpu/vinstr_registry

import hardware/disk as NactoDisk
import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let libfilesource = args[0]

    let file = FsApi.ResolvePath(libfilesource)
    
    if file == nil:
        ErrorApi.ThrowError(ErrorApi.newerr("include file not found", ErrorApi.SysError.ErrorSeverity.Error, ErrorApi.ErrTypes.CATEGORY_FS, ErrorApi.ErrTypes.FS_NOPATH))

    if file of NactoDisk.DiskTypes.Directory:
        ErrorApi.ThrowError(ErrorApi.newerr("cannot include a directory", ErrorApi.SysError.ErrorSeverity.Error, ErrorApi.ErrTypes.CATEGORY_FS, ErrorApi.ErrTypes.FS_INVCDO))
    let f = cast[NactoDisk.DiskTypes.File](file)
    if f.FileType != NactoDisk.DiskTypes.FT.ImportableBinary:
        ErrorApi.ThrowError(ErrorApi.newerr("file is not an importable binary", ErrorApi.SysError.ErrorSeverity.Error, ErrorApi.ErrTypes.CATEGORY_FS, ErrorApi.ErrTypes.FS_INVCDO))
    
    let data = FsApi.ReadFile(libfilesource).split('\n')
    var insertPos = procobj.ProcessState.ProgramCounter
    procobj.ProcessState.RunningProcessString.delete(insertPos)
    for line in data:
        if line.len > 0:
            procobj.ProcessState.RunningProcessString.insert(line, insertPos)
            inc insertPos
    return 0

register("INCLUDE", execute)