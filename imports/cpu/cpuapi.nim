import std/strutils
import std/strformat

import cpu/vinstr as VINSTRS
import process/procapi as ProcApi
import cpu/errors/all as BINERRC
export BINERRC
export VINSTRS

proc FatalCrash(errtype: BINERRC.BinaryError, reason: string, procobj: ProcApi.ProcTypes.ProcessObject): void =
    echo(fmt"A fatal crash has been triggered.{'\n'}FatalCrash Trace{'\n'}{'\n'}{'\n'}General{'\n'}Suspected line: {procobj.ProcessState.RunningProcessString[procobj.ProcessState.ProgramCounter]}{'\n'}Crash reason: {reason}{'\n'}Binary Error Code (BINERRC): {errtype.name}{'\n'}{'\n'}Program{'\n'}Name: {procobj.Name}{'\n'}Id: {procobj.Id}{'\n'}ProgramCounter: {$procobj.ProcessState.ProgramCounter}")
    return

proc ResolveOperand(token: string, procobj: ProcApi.ProcTypes.ProcessObject): string =
    if token.len >= 2 and token[0] == 'x':
        let regNum = parseInt(token[1..^1])

        if regNum < 0 or regNum > 7:
            raise newException(BINERRC.OutOfBounds, "exceeded confined space of CPU VM array")

        return $procobj.ProcessState.Vm[regNum]

    return token

proc EvaluateInstr(base: string, args: var seq[string], procobj: ProcApi.ProcTypes.ProcessObject): void =
    var ret: int = -1

    if args.len > 0:
        for i in 0..<args.len:
            args[i] = ResolveOperand(args[i], procobj)

    let handler = VINSTRS.vinstr_registry.lookup(base)
    if handler != nil:
        ret = handler(args, procobj)
    else:
        raise newException(BINERRC.InvalidInstruction, "unknown instruction \"" & base & "\"")
    return



proc tokenizeInstr*(str: string): seq[string] =
    var inGroup = false
    var cur: string
    for c in str:
        if c == '|':
            if inGroup:
                result.add(cur)
                cur.setLen(0)
                inGroup = false
            else:
                inGroup = true
        elif inGroup:
            cur.add(c)
        elif c != ' ':
            cur.add(c)
        elif cur.len > 0:
            result.add(cur)
            cur.setLen(0)
    if cur.len > 0:
        result.add(cur)

proc MakeProcess(procobj: ProcApi.ProcTypes.ProcessObject, exe: string): int =
    let instructions = exe.split('\n')

    procobj.ProcessState.RunningProcessString = instructions

    while procobj.ProcessState.IsRunning:
        let pc = procobj.ProcessState.ProgramCounter
        if pc >= instructions.len:
            raise newException(BINERRC.AttemptedExecuteNull, "attempted to execute null instruction") # this makes it so that a HALT instruction is required at the end of every program

        let instr = instructions[pc]
        if instr.len == 0:
            raise newException(BINERRC.ImplicitAbsentInstruction, "encountered an empty line")

        
        let tokenized = tokenizeInstr(instr)

        if tokenized.len == 0:
            continue

        let base = tokenized[0]
        var args = tokenized[1..^1]
        let prevPc = procobj.ProcessState.ProgramCounter
        EvaluateInstr(base, args, procobj)
        if procobj.ProcessState.ProgramCounter == prevPc:
            inc procobj.ProcessState.ProgramCounter
    return 0

proc ExecuteBinary*(name: string, origin: string, exe: string): int =
    var process = ProcApi.CreateProcess(name, origin)

    process.ProcessState.RunningProcess =
      proc(procobj: ProcApi.ProcessObject): int =
        try:
            return MakeProcess(procobj, exe)
        except BINERRC.BinaryError as e:
            FatalCrash(e[], e.msg, procobj)
            return -1

    process.ProcessState.IsRunning = true
    ProcApi.LinkProcess(process)
    let ret = process.ProcessState.RunningProcess(process)
    return ret

