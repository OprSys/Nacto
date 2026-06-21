import std/strutils
import std/tables

import process/procapi as ProcApi
import cpu/vinstr_registry
import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let uinstr = args[0]
    let args = args[1..^1]

    let customInstr = procobj.ProcessState.CustomInstrs.getOrDefault(uinstr)
    if customInstr == nil:
        ErrorApi.ThrowError(ErrorApi.newerr("custom instruction \"" & uinstr & "\" not defined", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_NOINSTR))

    procobj.ProcessState.ReturnBack.add(procobj.ProcessState.ProgramCounter + 1)
    procobj.ProcessState.CurrentCustomInstr.add(customInstr)

    for arg in args:
        var split = arg.split(':', maxsplit=1)
        let argName = split[0]
        var argValue = split[1]
        if argValue.len >= 2 and argValue[0] == 'x':
            let regNum = parseInt(argValue[1..^1])

            if regNum < 0 or regNum >= ProcApi.ProcTypes.VM_SIZE:
                ErrorApi.ThrowError(ErrorApi.newerr("register index out of bounds", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))

            argValue = $procobj.ProcessState.Vm[regNum]
        for argDef in customInstr.Arguments:
            if argDef.Name == argName:
                argDef.Value = parseInt(argValue)
                break
    discard vinstr_registry.lookup("JMP")(@[$customInstr.StartPC], procobj)
    return 0

register("ICALL", execute)