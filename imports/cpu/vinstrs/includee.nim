import std/strutils

import process/procapi as ProcApi
import fs/fsapi as FsApi
import cpu/vinstr_registry

import fs/errors/all as FSERRC

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let libfilesource = args[0]
    
    if FsApi.ResolvePath(libfilesource) == nil:
        raise newException(FSERRC.NoPath, "requested CoreDataObject.File not found \"" & libfilesource & "\"")
    
    let data = FsApi.ReadFile(libfilesource).split('\n')
    var insertPos = procobj.ProcessState.ProgramCounter
    procobj.ProcessState.RunningProcessString.delete(insertPos)
    for line in data:
        if line.len > 0:
            procobj.ProcessState.RunningProcessString.insert(line, insertPos)
            inc insertPos
    return 0

register("INCLUDE", execute)