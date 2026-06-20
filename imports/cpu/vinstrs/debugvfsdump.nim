import std/strutils

import process/procapi as ProcApi
import fs/fsapi as FsApi
import hardware/disk as NactoDisk
import cpu/vinstr_registry

proc printVfsTree(path: string, indent: int = 0) =
    for entry in FsApi.ListDirectory(path):
        let prefix = repeat("  ", indent)
        if entry of NactoDisk.Directory:
            let dir = cast[NactoDisk.DiskTypes.Directory](entry)
            echo(prefix & dir.Name & "/")
            let childPath = if path == "/": "/" & dir.Name else: path & "/" & dir.Name
            printVfsTree(childPath, indent + 1)
        else:
            let file = cast[NactoDisk.DiskTypes.File](entry)
            echo(prefix & file.Name & ":" & $file.FileType)

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    printVfsTree("/", 0)
    return 0

register("DEBUGVFSDUMP", execute)