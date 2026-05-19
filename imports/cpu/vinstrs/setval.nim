import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

import cpu/errors/all as BINERRC
import cpu/types/limits as LIMITS

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let reg = args[0]
    let value_to_set = args[1]
    let regint = parseInt(reg)
    if regint < 0 or regint > 7:
        raise newException(BINERRC.OutOfBounds, "register " & reg & " is not in the range of 0 to 7")
    let vtsint = parseInt(value_to_set)
    if vtsint < LIMITS.LIM_MINIMUM or vtsint > LIMITS.LIM_MAXIMUM:
        raise newException(BINERRC.LimitExceeded, value_to_set & " is not in the range of " & $LIMITS.LIM_MINIMUM & " to " & $LIMITS.LIM_MAXIMUM)
    procobj.ProcessState.Vm[regint] = parseInt(value_to_set)
    return 0

register("SETVAL", execute)