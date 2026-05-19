import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

import hardware/ram as RAM
import cpu/errors/all as BINERRC
import cpu/types/limits as LIMITS

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let val = args[0]
    let highram = args[1]
    let lowram = args[2]

    let valint = parseInt(val)
    let highramint = parseInt(highram)
    let lowramint = parseInt(lowram)

    if highramint < 0 or highramint > 32:
        raise newException(BINERRC.OutOfBounds, "RAM high-level slot " & highram & " is not in the range of 0 to 31")
    if lowramint < 0 or lowramint > 16:
        raise newException(BINERRC.OutOfBounds, "RAM low-level slot " & lowram & " is not in the range of 0 to 15")
    
    if valint < LIMITS.LIM_MINIMUM or valint > LIMITS.LIM_MAXIMUM:
        raise newException(BINERRC.LimitExceeded, val & " is not in the range of " & $LIMITS.LIM_MINIMUM & " to " & $LIMITS.LIM_MAXIMUM)

    RAM.RAM.Reg[highramint][lowramint] = valint
    return 0

register("STORE", execute)