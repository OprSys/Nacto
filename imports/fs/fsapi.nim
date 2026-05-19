import std/strutils
import std/json
import hardware/disk as NactoDisk
import cpu/cpuapi as CpuApi

proc ResolvePath*(path: string): NactoDisk.CoreDataObject =
    if path == "" or path == "/":
        return NactoDisk.get_root()

    var components: seq[string]
    for part in path.split('/'):
        if part != "" and part != ".":
            components.add(part)

    var current: NactoDisk.CoreDataObject
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


proc CreateFile*(path: string, name: string, kind: NactoDisk.FileTypes): NactoDisk.File =
    let parentObj = ResolvePath(path)

    if parentObj == nil:
        return nil

    if not (parentObj of NactoDisk.Directory):
        return nil

    let parentDir = cast[NactoDisk.Directory](parentObj)

    return NactoDisk.File(
        Name: name,
        Parent: parentDir,
        FileType: kind,
        Data: ""
    )

proc CreateDirectory*(path: string, name: string): NactoDisk.Directory =
    let parentObj = ResolvePath(path)

    if parentObj == nil:
        return nil

    if not (parentObj of NactoDisk.Directory):
        return nil

    let parentDir = cast[NactoDisk.Directory](parentObj)

    return NactoDisk.Directory(
        Name: name,
        Parent: parentDir,
        Children: @[]
    )

proc LinkCoreDataObject*(entry: NactoDisk.CoreDataObject): void =
    if entry.Parent == nil:
        return

    if not (entry.Parent of NactoDisk.Directory):
        return

    let parentDir = cast[NactoDisk.Directory](entry.Parent)
    parentDir.Children.add(entry)

proc ReadFile*(path: string): string =
    let obj = ResolvePath(path)
    if obj != nil and obj of NactoDisk.File:
        return NactoDisk.File(obj).Data
    return ""

proc WriteFile*(path: string, data: string): void =
    let obj = ResolvePath(path)
    if obj != nil and obj of NactoDisk.File:
        NactoDisk.File(obj).Data = data

proc ListDirectory*(path: string): seq[NactoDisk.CoreDataObject] =
    let obj = ResolvePath(path)
    if obj != nil and obj of NactoDisk.Directory:
        return NactoDisk.Directory(obj).Children
    return @[]

proc RenameCoreDataObject*(path: string, newName: string): void =
    let obj = ResolvePath(path)
    if obj != nil:
        obj.Name = newName

proc SaveRoot*(target: NactoDisk.CoreDataObject): JsonNode =
    result = %*{"name": target.Name}
    if target of NactoDisk.Directory:
        let dir = NactoDisk.Directory(target)
        result["type"] = %"directory"
        var children: seq[JsonNode] = @[]
        for child in dir.Children:
            children.add(SaveRoot(child))
        result["children"] = %children
    elif target of NactoDisk.File:
        let file = NactoDisk.File(target)
        result["type"] = %"file"
        result["fileType"] = %file.GetFileType()
        result["data"] = %file.Data

proc LoadRoot*(target: NactoDisk.Directory, data: JsonNode): void =
    target.Name = data["name"].getStr()
    target.Children.setLen(0)
    for child in data["children"]:
        if child["type"].getStr() == "directory":
            let dir = NactoDisk.Directory(
                Name: child["name"].getStr(),
                Parent: target,
                Children: @[]
            )
            LoadRoot(dir, child)
            target.Children.add(dir)
        else:
            var ft = NactoDisk.FileTypes.Invalid
            let ext = child["fileType"].getStr()
            for o in ord(low(NactoDisk.FileTypes)) .. ord(high(NactoDisk.FileTypes)):
                let ftt = NactoDisk.FileTypes(o)
                let dummy = NactoDisk.File(FileType: ftt, Name: "", Data: "")
                if dummy.GetFileType() == ext:
                    ft = ftt
                    break
            let file = NactoDisk.File(
                Name: child["name"].getStr(),
                Parent: target,
                FileType: ft,
                Data: child["data"].getStr()
            )
            target.Children.add(file)

proc ExecuteBinaryAtPath*(path: string): void =
    let obj = ResolvePath(path)
    if obj == nil or not (obj of NactoDisk.File):
        return
    let file = cast[NactoDisk.File](obj)
    if file.FileType != NactoDisk.FileTypes.Binary:
        return
    discard CpuApi.ExecuteBinary(file.Name, path, file.Data)
    return