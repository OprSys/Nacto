import fs/fsapi as FsApi
import hardware/disk as NactoDisk
import cpu/cpuapi as CpuApi

proc ExecuteBinaryAtPath*(path: string): void =
    let obj = FsApi.ResolvePath(path)
    if obj == nil or not (obj of NactoDisk.File):
        return
    let file = cast[NactoDisk.File](obj)
    if file.FileType != NactoDisk.FileTypes.Binary:
        return
    discard CpuApi.ExecuteBinary(file.Name, path, file.Data)
