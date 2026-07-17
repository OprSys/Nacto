import cpu/cpuapi as CpuApi
import process/procapi as ProcApi
import hardware/disk as NactoDisk
import fs/fsapi as FsApi
import helper/hasstdin

const QUANTUM = 128

proc RunScheduler*(): void =
    while true:
        for i in 0..<ProcApi.Processes.len:
            let procobj = ProcApi.Processes[i]
            if procobj == nil:
                continue
            if procobj.ProcessState.Running == ProcApi.ProcTypes.IsRunningState.WaitingForInput and hasstdin():
                procobj.ProcessState.Running = ProcApi.ProcTypes.IsRunningState.Running
        var anyAlive = false
        for i in 0..<ProcApi.Processes.len:
            let procobj = ProcApi.Processes[i]
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
                for i in 0..<ProcApi.Processes.len:
                    let p = ProcApi.Processes[i]
                    if p != nil and p.ProcessState.WaitingFor == procobj.Id:
                        p.ProcessState.Running = ProcApi.ProcTypes.IsRunningState.Running
                        p.ProcessState.WaitingFor = -1
                ProcApi.UnlinkProcess(procobj.Id)
        if not anyAlive:
            break
