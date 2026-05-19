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

    procobj.ProcessState.Vm[regint] = RAM.RAM.Reg[highramint][lowramint]
    return 0

register("LOAD", execute)