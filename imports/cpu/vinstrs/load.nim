import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

import hardware/ram as RAM
import cpu/errors/all as BINERRC
import cpu/types/limits as LIMITS

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let reg = args[2]
    let highram = args[0]
    let lowram = args[1]

    let regint = parseInt(reg)
    let highramint = parseInt(highram)
    let lowramint = parseInt(lowram)

    if highramint < 0 or highramint > 31:
        raise newException(BINERRC.OutOfBounds, "RAM high-level slot " & highram & " is not in the range of 0 to 31")
    if lowramint < 0 or lowramint > 15:
        raise newException(BINERRC.OutOfBounds, "RAM low-level slot " & lowram & " is not in the range of 0 to 15")
    
    if regint < LIMITS.LIM_MINIMUM or regint > LIMITS.LIM_MAXIMUM:
        raise newException(BINERRC.LimitExceeded, reg & " is not in the range of 0 to 7")

    procobj.ProcessState.Vm[regint] = RAM.RAM.Reg[highramint][lowramint]
    return 0

register("LOAD", execute)