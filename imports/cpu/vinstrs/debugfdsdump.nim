import std/strutils

import process/procapi as ProcApi
import fs/fsapi as FsApi
import hardware/disk as NactoDisk
import cpu/vinstr_registry

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    echo(procobj.ProcessState.FileDescriptors.repr)
    return 0

register("DEBUGFDSDUMP", execute)