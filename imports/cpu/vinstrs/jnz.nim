import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let reg = args[0]
    let jumpto = args[1]

    let regNum = parseInt(reg)
    let regVal = procobj.ProcessState.Vm[regNum - 1]

    if regVal != 0:
        discard vinstr_registry.lookup("JMP")(@[jumpto], procobj)
    return 0

register("JNZ", execute)