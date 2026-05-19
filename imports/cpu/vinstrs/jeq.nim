import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let val1 = args[0]
    let val2 = args[1]
    let jumpto = args[2]

    let val1int = parseInt(val1)
    let val2int = parseInt(val2)

    if val1int == val2int:
        discard vinstr_registry.lookup("JMP")(@[jumpto], procobj)
    return 0

register("JEQ", execute)