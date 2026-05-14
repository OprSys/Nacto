import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

import cpu/errors/all as BINERRC

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let reg = args[0]
    let value_to_set = args[1]
    let regint = parseInt(reg)
    if regint < 1 or regint > 8:
        raise newException(BINERRC.OutOfBounds, "register " & reg & " is not in the range of 1 to 8")
    procobj.ProcessState.Vm[regint - 1] = parseInt(value_to_set)
    return 0

register("SETVAL", execute)