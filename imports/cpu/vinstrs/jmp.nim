import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    procobj.ProcessState.ProgramCounter = parseInt(args[0]) - 1
    return 0

register("JMP", execute)