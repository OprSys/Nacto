import std/strutils
import fs/fsapi as FsApi
import hardware/disk as NactoDisk
import process/procapi as ProcApi
import cpu/types/ascii as Ascii

type ExeMetadata* = object
    Path*: string
    Name*: string
    Ma*: int
    Mi*: int
    Bf*: int

proc ParseExe*(data: string): ExeMetadata =
    result = ExeMetadata()
    let fields = data.split('\n')
    for fieldStr in fields:
        let parts = fieldStr.split(' ')
        if parts.len < 2:
            continue
        let fieldId = parseInt(parts[0])
        let values = parts[1..^1]
        case fieldId
        of 1:
            for v in values:
                result.Path.add(Ascii.ToChar(parseInt(v)))
        of 2:
            for v in values:
                result.Name.add(Ascii.ToChar(parseInt(v)))
        of 3:
            if values.len >= 1:
                result.Ma = parseInt(values[0])
            if values.len >= 2:
                result.Mi = parseInt(values[1])
            if values.len >= 3:
                result.Bf = parseInt(values[2])
        else:
            discard

proc ExecuteBinaryAtPath*(path: string): int =
    let obj = FsApi.ResolvePath(path)
    if obj == nil or not (obj of NactoDisk.DiskTypes.File):
        return -1
    let file = cast[NactoDisk.DiskTypes.File](obj)

    if file.FileType == NactoDisk.DiskTypes.FT.FileTypes.Executable:
        let meta = ParseExe(file.Data)
        let binObj = FsApi.ResolvePath(meta.Path)
        if binObj == nil or not (binObj of NactoDisk.DiskTypes.File):
            return -1
        let binFile = cast[NactoDisk.DiskTypes.File](binObj)
        if binFile.FileType != NactoDisk.DiskTypes.FT.FileTypes.Binary:
            return -1
        return ProcApi.ExecuteBinary(meta.Name, meta.Path, binFile.Data)
    elif file.FileType == NactoDisk.DiskTypes.FT.FileTypes.Binary:
        return ProcApi.ExecuteBinary(file.Name, path, file.Data)
