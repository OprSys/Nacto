import hardware/types/disktypes as DiskTypes
export DiskTypes

var internal_shared_state = DiskTypes.Directory(Name: "root", Children: @[])
var Root = internal_shared_state

proc get_root*(): DiskTypes.Directory =
    return Root
