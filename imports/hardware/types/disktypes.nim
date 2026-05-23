import hardware/types/filetypes as FT
export FT

type
    CoreDataObject* = ref object of RootObj
        Name*: string
        Parent*: CoreDataObject

    File* = ref object of CoreDataObject
        Data*: string
        FileType*: FT.FileTypes

    Directory* = ref object of CoreDataObject
        Children*: seq[CoreDataObject]

method Which*(self: CoreDataObject): string {.base.} = "CoreDataObject"

method Which*(self: File): string =
    return "file"

method Which*(self: Directory): string =
    return "directory"

method GetFileType*(self: CoreDataObject): string {.base.} = "inv"

method GetFileType*(self: File): string =
    case self.FileType
    of FT.FileTypes.Text:
        return "txt"
    of FT.FileTypes.Binary:
        return "exe"
    of FT.FileTypes.Invalid:
        return "inv"
    of FT.FileTypes.ImportableBinary:
        return "incl"
    else:
        return "inv"

proc `$`*(obj: CoreDataObject): string =
    if obj of File:
        return "File:" & obj.Name
    elif obj of Directory:
        return "Directory:" & obj.Name
    else:
        return "CoreDataObject:" & obj.Name

