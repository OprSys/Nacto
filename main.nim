# Nacto bootloader.
import std/os
import std/strutils
import std/json

import system/nacto as Nacto

const ROOTFS_PATH: string = "sim/rootfs.json"
const DISCLAIMER_PATH: string = "sim/DISCLAIMER.txt"

proc CreateSimulationDataFolder(): void =
    if dirExists("sim"):
        return
    else:
        createDir("sim")
        let disclaimer_msg = "DISCLAIMER! It is not recommended to modify these files directly. Doing so can result in unattended behavior, which can result in breaking the simulator.\n\nThe \"sim\" folder is required to be next to the Nacto binary in order for Nacto to function."

        writeFile(ROOTFS_PATH, "")
        writeFile(DISCLAIMER_PATH, disclaimer_msg)

proc loadInitramfs(): bool =
    let jsonPath = getAppDir() / "sim" / "rootfs.json"
    if fileExists(jsonPath):
        let data = parseFile(jsonPath)
        Nacto.FsApi.LoadRoot(Nacto.NactoDisk.get_root(), data)
        return true

    let initDir = getAppDir() / "initfs"
    if not dirExists(initDir):
        return false

    for path in walkDirRec(initDir):
        let relPath = relativePath(path, initDir)
        let parts = relPath.split({'/', '\\'})
        let fileName = parts[^1]

        var parentVfs = "/"
        for seg in parts[0..^2]:
            let checkPath = if parentVfs == "/": "/" & seg else: parentVfs & "/" & seg
            if Nacto.FsApi.ResolvePath(checkPath) == nil:
                let dir = Nacto.FsApi.CreateDirectory(parentVfs, seg)
                if dir != nil:
                    Nacto.FsApi.LinkCoreDataObject(dir)
            parentVfs = checkPath

        let dotParts = fileName.split('.')
        if dotParts.len >= 3 and dotParts[^1] == "txt":
            let vfsName = dotParts[0..^3].join(".")
            let vfsExt = dotParts[^2]

            var fileType = Nacto.NactoDisk.FT.FileTypes.Invalid
            for o in ord(low(Nacto.NactoDisk.FT.FileTypes)) .. ord(high(Nacto.NactoDisk.FT.FileTypes)):
                let ft = Nacto.NactoDisk.FT.FileTypes(o)
                let dummy = Nacto.NactoDisk.File(FileType: ft, Name: "", Data: "")
                if dummy.GetFileType() == vfsExt:
                    fileType = ft
                    break

            let file = Nacto.FsApi.CreateFile(parentVfs, vfsName, fileType)
            if file != nil:
                Nacto.FsApi.LinkCoreDataObject(file)
                file.Data = readFile(path)

    removeDir(initDir)
    return true



if loadInitramfs() == false:
    echo("error")
    quit(1)
CreateSimulationDataFolder()
var savedata = Nacto.FsApi.SaveRoot(Nacto.NactoDisk.get_root())
writeFile(ROOTFS_PATH, $savedata)
when defined(linux):
    import posix/termios
    var term: Termios
    discard tcgetattr(0, addr(term))
    term.c_lflag = term.c_lflag and not (ECHO or ICANON)
    discard tcsetattr(0, TCSANOW, addr(term))
discard Nacto.NactoExec.ExecuteBinaryAtPath("/BOOT/BOOTMASTERINIT")
##discard Nacto.NactoExec.ExecuteBinaryAtPath("/BIN/LOWOUPS")
Nacto.NactoSced.RunScheduler()
