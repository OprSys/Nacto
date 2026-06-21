import std/strutils
import std/strformat
import std/terminal

import cpu/vinstr as VINSTRS
import process/procapi as ProcApi
import error/errorapi as ErrorApi
import system/constants
export VINSTRS

proc waitforenter(): void =
    while true:
        let c = terminal.getch()
        if c == '\r' or c == '\n':
            break

proc vmToString(procobj: ProcApi.ProcTypes.ProcessObject): string =
    result = ""
    for i in 0..<procobj.ProcessState.Vm.len:
        if i > 0:
            result.add(", ")
        result.add($procobj.ProcessState.Vm[i])

proc error(e: ref ErrorApi.SysError.SysError, procobj: ProcApi.ProcTypes.ProcessObject): void =
    e.Context.ErrPC = procobj.ProcessState.ProgramCounter
    let formatted = ErrorApi.format(e, constants.DEBUG_MODE)
    if not constants.DEBUG_MODE:
        if e.Context.ErrSeverity == ErrorApi.SysError.ErrorSeverity.Fatal:
            echo(formatted)
            echo("vm")
            echo(vmToString(procobj))
            echo("\nproc")
            echo(procobj.Name & ":" & $procobj.Id)
    else:
        echo(formatted & "\n")
        if e.Context.ErrSeverity == ErrorApi.SysError.ErrorSeverity.Fatal:
            echo("vm")
            echo(vmToString(procobj))
            echo("\nproc")
            echo(procobj.Name & ":" & $procobj.Id & ", " & $e.Context.ErrPC)
    if e.Context.ErrSeverity == ErrorApi.SysError.ErrorSeverity.Fatal:
        procobj.ProcessState.IsRunning = false
        echo("\nPress Enter to exit.")
        waitforenter()
    elif e.Context.ErrSeverity == ErrorApi.SysError.ErrorSeverity.Error:
        if constants.DEBUG_MODE:
            procobj.ProcessState.IsRunning = false
            echo("\nPress Enter to continue execution. However, please note that things may not go expected.")
            waitforenter()
            procobj.ProcessState.IsRunning = true

proc ResolveOperand(token: string, procobj: ProcApi.ProcTypes.ProcessObject): string =
    if token.len >= 2 and token[0] == 'x':
        let regNum = parseInt(token[1..^1])

        if regNum < 0 or regNum >= ProcApi.ProcTypes.VM_SIZE:
            ErrorApi.ThrowError(ErrorApi.newerr("register index out of bounds", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))

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
        ErrorApi.ThrowError(ErrorApi.newerr("unknown instruction \"" & base & "\"", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_NOINSTR))
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
    if constants.DEBUG_MODE and constants.DEBUG_VERBOSE:
        echo("The CPU has been invoked.")
        echo("Program \"" & procobj.Name & "\", ID \"" & $(procobj.Id) & "\".")
    let instructions = exe.split('\n')
    if constants.DEBUG_MODE and constants.DEBUG_VERBOSE:
        echo("Instructions to run: " & $(instructions.len) & "\n")

    procobj.ProcessState.RunningProcessString = instructions

    while procobj.ProcessState.IsRunning:
        let pc = procobj.ProcessState.ProgramCounter
        if pc >= procobj.ProcessState.RunningProcessString.len:
            error(ErrorApi.newerr("program counter exceeded program bounds", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_PRGRMEND), procobj)

        let instr = procobj.ProcessState.RunningProcessString[pc]
        if constants.DEBUG_MODE and constants.DEBUG_VERBOSE:
            echo("Instruction: " & instr)
            echo("Program counter: " & $pc)

        if instr.len == 0:
            error(ErrorApi.newerr(
                "no instruction to execute",
                ErrorApi.SysError.ErrorSeverity.Fatal,
                ErrorApi.ErrTypes.CATEGORY_CPU,
                ErrorApi.ErrTypes.CPU_ABSENTINSTR
            ), procobj)
            break

        
        let tokenized = tokenizeInstr(instr)

        if tokenized.len == 0:
            continue

        let base = tokenized[0]
        var args = tokenized[1..^1]

        if constants.DEBUG_MODE and constants.DEBUG_VERBOSE:
            echo("\nInstruction RunningProcessString[" & $pc & "] tokenized.")
            echo("Token: " & $tokenized)
            echo("Base: " & base)
            echo("Arguments: " & $args)

        let cur = if procobj.ProcessState.CurrentCustomInstr.len > 0: procobj.ProcessState.CurrentCustomInstr[^1] else: nil
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
        if constants.DEBUG_MODE and constants.DEBUG_VERBOSE:
            echo("prevPc, prevLen = " & $prevPc & ", " & $prevLen)
        try:
            if DEBUG_MODE and DEBUG_VERBOSE:
                echo("Executing instruction \"" & base & "\"...")
            EvaluateInstr(base, args, procobj)
        except ErrorApi.SysError.SysError as e:
            error(e, procobj)

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

