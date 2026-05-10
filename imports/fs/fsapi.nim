import std/strutils
import hardware/disk as NactoDisk

type
    FileType* = NactoDisk.FileTypes

proc `$`*(self: NactoDisk.CoreDataObject): string =
    if self == nil: "nil" else: self.Name

proc ResolvePath*(path: string): NactoDisk.CoreDataObject =
    if path == "" or path == "/":
        return NactoDisk.get_root()

    var components: seq[string]
    for part in path.split('/'):
        if part != "" and part != ".":
            components.add(part)

    var current: NactoDisk.CoreDataObject
    if path[0] == '/':
        current = NactoDisk.get_root()
    else:
        current = NactoDisk.get_root()

    for part in components:
        if part == "..":
            if current.Parent != nil:
                current = current.Parent
            else:
                return nil
        else:
            if current of NactoDisk.Directory:
                let dir = NactoDisk.Directory(current)
                var found = false
                for child in dir.Children:
                    if child.Name == part:
                        current = child
                        found = true
                        break
                if not found:
                    return nil
            else:
                return nil

    return current


proc CreateFile*(path: string, name: string, kind: NactoDisk.FileTypes): void =
    let parentObj = ResolvePath(path)

    if parentObj == nil:
        return

    if not (parentObj of NactoDisk.Directory):
        return

    let parentDir = cast[NactoDisk.Directory](parentObj)

    let file = NactoDisk.File(
        Name: name,
        Parent: parentDir,
        FileType: kind,
        Data: ""
    )

    parentDir.Children.add(file)

proc CreateDirectory*(path: string, name: string): void =
    let parentObj = ResolvePath(path)

    if parentObj == nil:
        return

    if not (parentObj of NactoDisk.Directory):
        return

    let parentDir = cast[NactoDisk.Directory](parentObj)

    let file = NactoDisk.Directory(
        Name: name,
        Parent: parentDir,
        Children: @[]
    )

    parentDir.Children.add(file)
