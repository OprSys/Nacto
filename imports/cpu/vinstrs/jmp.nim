import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let targetStr = args[0]
    if targetStr.len > 0 and targetStr[0] == '+':
        procobj.ProcessState.ProgramCounter += parseInt(targetStr[1..^1])
    elif targetStr.len > 0 and targetStr[0] == '-':
        procobj.ProcessState.ProgramCounter -= parseInt(targetStr[1..^1])
    else:
        procobj.ProcessState.ProgramCounter = parseInt(targetStr)
    return 0

register("JMP", execute)