import std/strutils
import std/json
import hardware/disk as NactoDisk


proc ResolvePath*(path: string): NactoDisk.DiskTypes.CoreDataObject =
    if path == "" or path == "/":
        return NactoDisk.get_root()

    var components: seq[string]
    for part in path.split('/'):
        if part != "" and part != ".":
            components.add(part)

    var current: NactoDisk.DiskTypes.CoreDataObject
    current = NactoDisk.get_root()

    for part in components:
        if part == "..":
            if current.Parent != nil:
                current = current.Parent
            else:
                return nil
        else:
            if current of NactoDisk.DiskTypes.Directory:
                let dir = NactoDisk.DiskTypes.Directory(current)
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


proc CreateFile*(path: string, name: string, kind: NactoDisk.DiskTypes.FT.FileTypes): NactoDisk.DiskTypes.File =
    let parentObj = ResolvePath(path)

    if parentObj == nil:
        return nil

    if not (parentObj of NactoDisk.DiskTypes.Directory):
        return nil

    let parentDir = cast[NactoDisk.DiskTypes.Directory](parentObj)

    var file = NactoDisk.DiskTypes.File()
    file.Name = name
    file.Parent = parentDir
    file.FileType = kind
    file.Data = ""
    return file

proc CreateDirectory*(path: string, name: string): NactoDisk.DiskTypes.Directory =
    let parentObj = ResolvePath(path)

    if parentObj == nil:
        return nil

    if not (parentObj of NactoDisk.DiskTypes.Directory):
        return nil

    let parentDir = cast[NactoDisk.DiskTypes.Directory](parentObj)

    var dir = NactoDisk.DiskTypes.Directory()
    dir.Name = name
    dir.Parent = parentDir
    dir.Children = @[]
    return dir

proc LinkCoreDataObject*(entry: NactoDisk.DiskTypes.CoreDataObject): void =
    if entry.Parent == nil:
        return

    if not (entry.Parent of NactoDisk.DiskTypes.Directory):
        return

    let parentDir = cast[NactoDisk.DiskTypes.Directory](entry.Parent)
    parentDir.Children.add(entry)

proc ReadFile*(path: string): string =
    let obj = ResolvePath(path)
    if obj != nil and obj of NactoDisk.DiskTypes.File:
        return NactoDisk.DiskTypes.File(obj).Data
    return ""

proc WriteFile*(path: string, data: string): void =
    let obj = ResolvePath(path)
    if obj != nil and obj of NactoDisk.DiskTypes.File:
        NactoDisk.DiskTypes.File(obj).Data = data

proc ListDirectory*(path: string): seq[NactoDisk.DiskTypes.CoreDataObject] =
    let obj = ResolvePath(path)
    if obj != nil and obj of NactoDisk.DiskTypes.Directory:
        return NactoDisk.DiskTypes.Directory(obj).Children
    return @[]

proc RenameCoreDataObject*(path: string, newName: string): void =
    let obj = ResolvePath(path)
    if obj != nil:
        obj.Name = newName

proc SaveRoot*(target: NactoDisk.DiskTypes.CoreDataObject): JsonNode =
    result = %*{"name": target.Name}
    if target of NactoDisk.DiskTypes.Directory:
        let dir = NactoDisk.DiskTypes.Directory(target)
        result["type"] = %"directory"
        var children: seq[JsonNode] = @[]
        for child in dir.Children:
            children.add(SaveRoot(child))
        result["children"] = %children
    elif target of NactoDisk.DiskTypes.File:
        let file = NactoDisk.DiskTypes.File(target)
        result["type"] = %"file"
        result["fileType"] = %file.GetFileType()
        result["data"] = %file.Data

proc LoadRoot*(target: NactoDisk.DiskTypes.Directory, data: JsonNode): void =
    target.Name = data["name"].getStr()
    target.Children.setLen(0)
    for child in data["children"]:
        if child["type"].getStr() == "directory":
            var dir = NactoDisk.DiskTypes.Directory()
            dir.Name = child["name"].getStr()
            dir.Parent = target
            dir.Children = @[]
            LoadRoot(dir, child)
            target.Children.add(dir)
        else:
            var ft = default(NactoDisk.DiskTypes.FT.FileTypes)
            let ext = child["fileType"].getStr()
            for o in ord(low(NactoDisk.DiskTypes.FT.FileTypes)) .. ord(high(NactoDisk.DiskTypes.FT.FileTypes)):
                let ftt = NactoDisk.DiskTypes.FT.FileTypes(o)
                var dummy = NactoDisk.DiskTypes.File()
                dummy.FileType = ftt
                dummy.Name = ""
                dummy.Data = ""
                if dummy.GetFileType() == ext:
                    ft = ftt
                    break
            var file = NactoDisk.DiskTypes.File()
            file.Name = child["name"].getStr()
            file.Parent = target
            file.FileType = ft
            file.Data = child["data"].getStr()
            target.Children.add(file)