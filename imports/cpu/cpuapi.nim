import std/strutils
import std/strformat

import cpu/vinstr as VINSTRS
import process/procapi as ProcApi
import cpu/errors/all as BINERRC
import fs/errors/all as FSERRC
export BINERRC
export VINSTRS

proc trace(err: ref CatchableError, procobj: ProcApi.ProcTypes.ProcessObject, isFatal: bool): void =
    var groupName: string
    var errCode: string
    if err of BINERRC.BinaryError:
        groupName = "BinaryError"
        errCode = "(BINERRC)"
    elif err of FSERRC.FSError:
        groupName = "FSError"
        errCode = "(FSERRC)"
    else:
        groupName = "CatchableError"
        errCode = "(UNKERRC)"
    let crashType = if isFatal: "FatalCrash" else: "Error"
    let article = if isFatal: "A fatal crash" else: "An error"
    echo(fmt"{article} has been triggered.{'\n'}{crashType} Trace{'\n'}{'\n'}{'\n'}General{'\n'}Suspected line: {procobj.ProcessState.RunningProcessString[procobj.ProcessState.ProgramCounter]}{'\n'}Crash reason: {err.msg}{'\n'}Crash type: {errCode} {groupName}.{err.name}{'\n'}{'\n'}Program{'\n'}Name: {procobj.Name}{'\n'}Id: {procobj.Id}{'\n'}ProgramCounter: {$procobj.ProcessState.ProgramCounter}")

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

    var expanded: seq[string] = @[]
    for token in result:
        block expandCheck:
            if token.len >= 4 and token[0] == 'y':
                let dotPos = token.find('.', 1)
                if dotPos > 1 and dotPos < token.len - 1:
                    let bankPart = token[1..dotPos-1]
                    let slotPart = if dotPos < token.len - 2 and token[dotPos+1] == 'y':
                            token[dotPos+2..^1]
                        else:
                            token[dotPos+1..^1]
                    try:
                        discard parseInt(bankPart)
                        discard parseInt(slotPart)
                        expanded.add(bankPart)
                        expanded.add(slotPart)
                        break expandCheck
                    except ValueError:
                        discard
            expanded.add(token)
    result = expanded

proc MakeProcess(procobj: ProcApi.ProcTypes.ProcessObject, exe: string): int =
    let instructions = exe.split('\n')

    procobj.ProcessState.RunningProcessString = instructions

    while procobj.ProcessState.IsRunning:
        let pc = procobj.ProcessState.ProgramCounter
        if pc >= procobj.ProcessState.RunningProcessString.len:
            raise newException(BINERRC.AttemptedExecuteNull, "attempted to execute null instruction") # this makes it so that a HALT instruction is required at the end of every program

        let instr = procobj.ProcessState.RunningProcessString[pc]
        if instr.len == 0:
            raise newException(BINERRC.ImplicitAbsentInstruction, "encountered an empty line")

        
        let tokenized = tokenizeInstr(instr)

        if tokenized.len == 0:
            continue

        let base = tokenized[0]
        var args = tokenized[1..^1]

        let cur = procobj.ProcessState.CurrentCustomInstr
        if cur != nil:
            for i in 0..<args.len:
                if args[i].len > 1 and args[i][0] == '$':
                    let argName = args[i][1..^1]
                    for argDef in cur.Arguments:
                        if argDef.Name == argName:
                            args[i] = $argDef.Value
                            break

        let prevPc = procobj.ProcessState.ProgramCounter
        let prevLen = procobj.ProcessState.RunningProcessString.len
        try:
            EvaluateInstr(base, args, procobj)
        except BINERRC.BinaryError as e:
            trace(e, procobj, true)
            procobj.ProcessState.IsRunning = false
        except FSERRC.FSError as e:
            trace(e, procobj, e.IsFatal)
            if e.IsFatal:
                procobj.ProcessState.IsRunning = false

        if procobj.ProcessState.ProgramCounter == prevPc:
            if procobj.ProcessState.RunningProcessString.len == prevLen:
                inc procobj.ProcessState.ProgramCounter
    return 0

proc ExecuteBinary*(name: string, origin: string, exe: string): int =
    var process = ProcApi.CreateProcess(name, origin)

    process.ProcessState.RunningProcess =
      proc(procobj: ProcApi.ProcessObject): int =
            return MakeProcess(procobj, exe)


    process.ProcessState.IsRunning = true
    ProcApi.LinkProcess(process)
    let ret = process.ProcessState.RunningProcess(process)
    return ret

