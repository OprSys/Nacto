import std/strutils

import process/procapi as ProcApi
import fs/fsapi as FsApi
import cpu/vinstr_registry

import fs/errors/all as FSERRC
import hardware/disk as NactoDisk

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let libfilesource = args[0]

    let file = FsApi.ResolvePath(libfilesource)
    
    if file == nil:
        raise newException(FSERRC.NoPath, "requested CoreDataObject not found \"" & libfilesource & "\"")

    if file of NactoDisk.DiskTypes.Directory:
        raise newException(FSERRC.InvalidCDOType, "requested CoreDataObject is of a Directory, but was expected to be a File")
    let f = cast[NactoDisk.DiskTypes.File](file)
    if f.FileType != NactoDisk.DiskTypes.FT.ImportableBinary:
        var inclfile = NactoDisk.DiskTypes.File()
        inclfile.FileType = NactoDisk.DiskTypes.FT.ImportableBinary
        raise newException(FSERRC.InvalidCDOType, "requested CoreDataObject is of \"" & f.GetFileType() & "\", but was expected to a \"" & inclfile.GetFileType() & "\"")
    
    let data = FsApi.ReadFile(libfilesource).split('\n')
    var insertPos = procobj.ProcessState.ProgramCounter
    procobj.ProcessState.RunningProcessString.delete(insertPos)
    for line in data:
        if line.len > 0:
            procobj.ProcessState.RunningProcessString.insert(line, insertPos)
            inc insertPos
    return 0

register("INCLUDE", execute)