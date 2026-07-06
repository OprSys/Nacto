import cpu/cpuapi as CpuApi
import process/procapi as ProcApi
import hardware/disk as NactoDisk
import fs/fsapi as FsApi
import helper/hasstdin

const QUANTUM = 1

proc RunScheduler*(): void =
    while true:
        for procobj in ProcApi.Processes:
            if procobj == nil:
                continue
            if procobj.ProcessState.Running == ProcApi.ProcTypes.IsRunningState.Blocking and hasstdin():
                procobj.ProcessState.Running = ProcApi.ProcTypes.IsRunningState.Running
        var anyAlive = false
        for procobj in ProcApi.Processes:
            if procobj == nil:
                continue
            if procobj.ProcessState.Running != ProcApi.ProcTypes.IsRunningState.Terminated:
                anyAlive = true
                var steps = 0
                if not procobj.ProcessState.WasScanned:
                    if not CpuApi.PreRuntime(procobj):
                        continue
                    procobj.ProcessState.WasScanned = true
                while steps < QUANTUM and procobj.ProcessState.Running == ProcApi.ProcTypes.IsRunningState.Running:
                    if not CpuApi.ProcessStep(procobj):
                        break
                    inc steps
            if procobj.ProcessState.Running == ProcApi.ProcTypes.IsRunningState.Terminated:
                ProcApi.UnlinkProcess(procobj.Id)
        if not anyAlive:
            break