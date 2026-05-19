import std/os
import std/strutils
import std/json
import fs/fsapi as FS
import hardware/disk as NactoDisk

const ROOTFS_PATH: string = "sim/rootfs.json"
const DISCLAIMER_PATH: string = "sim/DISCLAIMER.txt"

proc CreateSimulationDataFolder(): void =
    if dirExists("sim"):
        return
    else:
        createDir("sim")
        let disclaimer_msg = "DISCLAIMER! It is not recommended to modify these files directly. Doing so can result in unattended behavior, which can result in breaking the simulator.\n\nThe 'sim' folder is required to be next to the Nacto binary in order for Nacto to function."

        writeFile(ROOTFS_PATH, "")
        writeFile(DISCLAIMER_PATH, disclaimer_msg)

proc loadInitramfs(): bool =
    let jsonPath = getAppDir() / "sim" / "rootfs.json"
    if fileExists(jsonPath):
        let data = parseFile(jsonPath)
        FS.LoadRoot(NactoDisk.get_root(), data)
        return true

    let initDir = getAppDir() / "initramfs"
    if not dirExists(initDir):
        return false

    for path in walkDirRec(initDir):
        let relPath = relativePath(path, initDir)
        let parts = relPath.split({'/', '\\'})
        let fileName = parts[^1]

        var parentVfs = "/"
        for seg in parts[0..^2]:
            let checkPath = if parentVfs == "/": "/" & seg else: parentVfs & "/" & seg
            if FS.ResolvePath(checkPath) == nil:
                let dir = FS.CreateDirectory(parentVfs, seg)
                if dir != nil:
                    FS.LinkCoreDataObject(dir)
            parentVfs = checkPath

        let dotParts = fileName.split('.')
        if dotParts.len >= 3 and dotParts[^1] == "txt":
            let vfsName = dotParts[0..^3].join(".")
            let vfsExt = dotParts[^2]

            var fileType = NactoDisk.FT.FileTypes.Invalid
            for o in ord(low(NactoDisk.FT.FileTypes)) .. ord(high(NactoDisk.FT.FileTypes)):
                let ft = NactoDisk.FT.FileTypes(o)
                let dummy = NactoDisk.File(FileType: ft, Name: "", Data: "")
                if dummy.GetFileType() == vfsExt:
                    fileType = ft
                    break

            let file = FS.CreateFile(parentVfs, vfsName, fileType)
            if file != nil:
                FS.LinkCoreDataObject(file)
                file.Data = readFile(path)

    removeDir(initDir)
    return true

proc printVfsTree(path: string, indent: int = 0) =
    for entry in FS.ListDirectory(path):
        let prefix = repeat("  ", indent)
        if entry of NactoDisk.Directory:
            echo prefix & entry.Name & "/"
            let childPath = if path == "/": "/" & entry.Name else: path & "/" & entry.Name
            printVfsTree(childPath, indent + 1)
        else:
            echo prefix & entry.Name

if loadInitramfs() == false:
    echo("error")
CreateSimulationDataFolder()
var savedata = FS.SaveRoot(NactoDisk.get_root())
writeFile(ROOTFS_PATH, $savedata)
FS.ExecuteBinaryAtPath("/boot/kernel")