---
title: "What is EDR? A Red Teamer's Primer on Endpoint Detection & Response"
date: 2026-05-12
author: Spy0x7
tags: [red-team, edr, windows, evasion, internals]
---

# What is EDR? A Red Teamer's Primer on Endpoint Detection & Response

If you've spent any time around modern Windows engagements you've heard the three letters that ruin shells: **EDR**. Endpoint Detection and Response is the layer between your payload and the operator who responds to alerts at 3 AM. AV looks at *what a file is*. EDR looks at *what a process does*. That difference is the whole game.

This post is my own primer — what an EDR actually is, how it sees you, and the categories of evasion red teamers use. It is not a copy-paste tutorial; it's the mental model I wish someone had drilled into me earlier. If you want a deeper, more research-flavored read on the same topic, go read [`0xdbgman`'s "EDR Internals: Research & Bypass"](https://0xdbgman.github.io/posts/edr-internals-research-and-bypass/) — it's excellent, and most of what I cover below I treat as the *short version* of that material.

---

## 1. What an EDR Actually Is

Strip the marketing away and an EDR is a **distributed sensor + correlation engine**. On every endpoint it deploys a collection of components that quietly record what happens on the box, normalize that into events, and ship the events to a cloud backend where rules and ML decide whether to alert.

Every major vendor — Defender for Endpoint (MDE), CrowdStrike Falcon, SentinelOne, Elastic, Sophos Intercept X — implements roughly the same architecture:

- **A user-mode service** (e.g. `MsSense.exe` for MDE). The "brain" on the host.
- **A user-mode DLL injected into every process** to set hooks inside `ntdll.dll`.
- **One or more kernel drivers** registering kernel callbacks.
- **A file-system mini-filter driver** that sees every file/IRP operation.
- **An ETW (Event Tracing for Windows) consumer** subscribed to a dozen+ providers — including the powerful `Microsoft-Windows-Threat-Intelligence` (ETW-TI) provider.
- **Network inspection** via WFP (Windows Filtering Platform) callout drivers.
- **A cloud transport** that uploads telemetry and pulls down detection content.

Why this matters operationally: **detection is layered**. If you only think about the user-mode hooks (which most "syscall bypass" tutorials focus on), you'll still get caught by the kernel callbacks, ETW-TI, and the cloud-side correlation. Bypassing one layer is not bypassing the EDR.

---

## 2. How EDR Sees You

A simple win32 call like `CreateFileW("C:\\Users\\victim\\hello.txt", ...)` goes through this chain:

```
CreateFileW   (kernel32.dll)
   └─ CreateFileW       (kernelbase.dll)
        └─ NtCreateFile (ntdll.dll)   ← user-mode hook lives here
              └─ syscall              ← transition to kernel
                    └─ NtCreateFile   (ntoskrnl.exe)
                          └─ kernel callbacks fire
                          └─ mini-filter IRP_MJ_CREATE
                          └─ ETW providers emit events
```

Every horizontal line is a potential observation point for an EDR. Let me walk through the four main visibility layers.

### 2.1 User-Mode Hooks

The injected EDR DLL rewrites the first instructions of sensitive `ntdll` stubs (`NtAllocateVirtualMemory`, `NtProtectVirtualMemory`, `NtCreateThreadEx`, `NtMapViewOfSection`, etc.) with a `JMP` into EDR-controlled inspection code. The hook can read arguments, the calling stack, the contents of buffers — then forward to the real syscall.

Pros for EDR: rich context, easy to deploy.
Cons for EDR: lives in the *target process address space*, which means the attacker can read it, patch it, or skip it.

This is the layer most public "syscall bypass" content focuses on, and frankly, **it's the easiest layer to defeat**. That's also why it's no longer the only thing modern EDRs rely on.

### 2.2 Kernel Callbacks

Drivers can register with the kernel to receive notifications:

- `PsSetCreateProcessNotifyRoutineEx` — every process creation.
- `PsSetCreateThreadNotifyRoutine` — every thread creation, including remote threads.
- `PsSetLoadImageNotifyRoutine` — every DLL / image load.
- `ObRegisterCallbacks` — every handle open. Critically, EDR uses this to **strip dangerous access masks** (e.g. `PROCESS_VM_WRITE` against `lsass.exe`).
- `CmRegisterCallbackEx` — every registry operation.

You cannot patch these from user mode. They run in the attacker's process context but in kernel mode. To kill them you need either signed kernel code, a vulnerable signed driver (BYOVD), or an exploit. All three are loud and increasingly mitigated by HVCI and the Microsoft Vulnerable Driver Blocklist.

### 2.3 The Mini-Filter

The file-system mini-filter framework lets EDR see every `IRP_MJ_CREATE`, `IRP_MJ_WRITE`, `IRP_MJ_SET_INFORMATION` — i.e., every dropped file, every overwrite, every rename. If you write a payload to disk, this layer sees it.

### 2.4 ETW and ETW-TI

ETW is Windows' built-in tracing system. Two flavors matter:

- **Regular ETW providers** (`Microsoft-Windows-Kernel-Process`, `…-Network`, `…-Registry`, etc.) — useful, mostly not security-grade.
- **ETW-TI** (`Microsoft-Windows-Threat-Intelligence`) — restricted to **PPL** (Protected Process Light) consumers. This is the gold mine: it emits events for `NtAllocateVirtualMemory`, `NtProtectVirtualMemory`, `NtMapViewOfSection`, `NtReadVirtualMemory`, `NtWriteVirtualMemory`, queued APCs, driver loads, and more — *with full call-stack context*, from the kernel side.

You cannot subscribe to ETW-TI without PPL. EDR processes are signed and run as PPL specifically for this reason. ETW-TI is the modern crown jewel of behavioral detection.

---

## 3. The Detection Engines

Telemetry on its own isn't a detection. EDRs feed events into four stacked engines:

1. **Static engine** — signatures, YARA, hash reputation, PE structure checks. Cheap, runs first.
2. **Dynamic engine** — behavioral rules over the event stream. "Office app → cmd.exe → powershell.exe with `-enc`" type chains.
3. **Heuristic engine** — composite rules combining multiple weak signals. Built in something like KQL on the cloud side.
4. **Machine-learning engine** — two flavors. *Static ML* over PE features. *Behavioral ML* over event sequences (essentially: does this process look like every other benign process?).

The important insight: **bypassing one engine doesn't mean bypassing the others**. An evasive loader with a clean YARA fingerprint can still light up the behavioral ML model because its call sequence is *weird*. Conversely, a "normal-looking" process doing something forbidden (e.g. handle open to lsass with `PROCESS_VM_READ`) can ace ML and die instantly on a heuristic rule.

---

## 4. Bypass Categories (The Honest Map)

This is the part everyone wants. I'm going to refuse to give you a copy-paste payload, but I'll give you the **mental map** — what each technique attacks, and what it does *not* defeat. Code-level depth is in 0xdbgman's article and the references at the end.

### 4.1 Static Evasion

Symbol/section renaming, string encryption, control-flow flattening, API hashing, runtime export resolution via PEB walking. Goal: defeat the static engine.

What it does **not** defeat: anything behavioral. A perfectly obfuscated binary that calls `WriteProcessMemory` → `CreateRemoteThread` against `lsass.exe` still trips the dynamic engine.

### 4.2 Unhooking and Syscall Bypass

The classic move: skip the user-mode hook in `ntdll`.

- **Manual unhooking** — load a fresh copy of `ntdll.dll` from disk and restore the `.text` section. Trips memory-scanning rules.
- **Direct syscalls** — embed the `syscall` instruction in your binary, using techniques like *Hell's Gate* (parse stub bytes), *Halo's Gate* (fall back to neighboring stubs when patched), *FreshyCalls* (sort exports by SSN), *SysWhispers* family, *RecycledGate*.
- **Indirect syscalls** — execute the syscall *from inside `ntdll.dll`* via a gadget, so the return address stays in a legitimate module. This is now table stakes.

What it does **not** defeat: kernel callbacks, ETW-TI (which fires *after* the syscall enters the kernel), or call-stack analysis on the kernel side.

### 4.3 Injection — Ranked by Loudness

From loudest to quietest, roughly:

| Technique | Why It's Loud | Why It Still Works Sometimes |
|---|---|---|
| `CreateRemoteThread` | Hits thread-creation callback. | Easy to write. |
| APC injection (`NtQueueApcThreadEx`) | Cross-process APC is in ETW-TI. | No `CreateRemoteThread` event. |
| Process hollowing | PEB inconsistency, mapped image mismatch. | Bypasses some path-based rules. |
| Process ghosting / doppelgänging | Abuses NTFS transactions / delete-pending. | Defeats most static signatures. |
| Reflective DLL loading | Private RX memory with no backing file. | Defeats path/image-load rules. |
| Module stomping | Lives in a real signed module's memory. | Looks image-backed to memory scanners. |
| Early-bird APC | Runs before EDR's DLL fully attaches. | Hits a real timing window. |
| Thread name spoofing / fiber injection | Avoids creating a tracked thread. | Niche but effective. |

There is no "undetectable" injection technique. There are techniques with **different telemetry footprints**, and the right choice depends on what the target EDR actually weights.

### 4.4 Sleep Obfuscation

Most loaders spend 99% of their wall-clock time *sleeping*. During that time the implant memory is `RX` and full of shellcode — trivial for an in-memory scanner. Techniques like **Ekko** (timer-queue ROP), **FOLIAGE** (APC chain), **Zilean**, **Cronos**, **DeathSleep**, **DreamWalkers** flip the implant region to `RW`, encrypt it, sleep, then decrypt and re-flip to `RX` on wake.

What this defeats: in-memory scans.
What this generates: a *lot* of `NtProtectVirtualMemory` calls — which ETW-TI sees. Frequency analysis catches naïve implementations.

### 4.5 Call-Stack Spoofing

When EDR captures a stack on a sensitive call, your return addresses point into your beacon, not into `kernel32`/`ntdll` like a legitimate thread. That alone is a signal.

**SilentMoonwalk** and similar tools desynchronize the unwinder so the actual execution path is preserved but the stack *as captured by the analyzer* looks like a benign one. This is the current high-ground for stealthy callbacks.

### 4.6 AMSI / ETW Patching — and the Patchless Version

The old way: patch `AmsiScanBuffer` or `EtwEventWrite` in memory with `xor rax,rax; ret`. EDR vendors got wise — they hash and re-verify the `.text` of these functions.

The patchless way: install a **hardware breakpoint** (DR0–DR3 registers) on `AmsiScanBuffer`, then in the vectored exception handler tamper with the arguments or return value. No bytes change in `.text`, so integrity checks pass. Same trick works on a number of ETW emit points.

### 4.7 PPL / BYOVD Land

If you can run code in the kernel — for example by loading a vulnerable signed driver — you can elevate your own process to PPL, blind ETW-TI from user space, unregister callbacks, etc. This is the "boss-level" bypass, and it is exactly what HVCI + the Vulnerable Driver Blocklist exist to stop. On a hardened, modern Windows 11 box, this path is mostly closed.

---

## 5. What Actually Survives All of the Above

This is the part that matters most. Even with perfect tradecraft, the following kernel-mode signals **still get emitted**:

- ETW-TI events for memory operations (no matter how you syscall).
- Object-handle callbacks with stripped access masks (you cannot get `PROCESS_VM_WRITE` on `lsass` from a non-PPL process without going through the callback).
- Image-load callbacks (every DLL touched on disk).
- Intel TDT / hardware-based telemetry on supported CPUs (CET shadow stacks, BTS, etc.).

Conclusion: **user-mode hook bypass is solved tradecraft**. Kernel-side telemetry is the real problem. Modern red-team tradecraft is about *minimizing emitted kernel events*, not about hiding from user-mode hooks.

Practical consequences:

- Stay off disk. Every disk write is a mini-filter event.
- Stay off lsass directly. Use indirect creds (DPAPI offline, Kerberoasting, etc.) where possible.
- Sleep long, sleep encrypted, sleep with stack spoofing.
- Pick injection by *telemetry footprint*, not by tutorial age.
- Reduce dwell time. Time on host = events emitted = correlations possible.

---

## 6. How I'd Approach Researching a Specific EDR

Roughly the same loop 0xdbgman documents:

1. **Build a lab.** Isolated VM, snapshot baselines, second VM as the simulated C2 receiver.
2. **Enumerate.** `tasklist /svc`, `driverquery /si`, `fltmc instances`, `logman query providers`, `Get-WinEvent -ListProvider`.
3. **Observe.** Procmon + PerfView + Sysmon running during normal red-team actions to see what the EDR captures.
4. **Reverse the user-mode and kernel-mode components.** IDA / Ghidra on the service binary and the driver. Look at registered callbacks and the IOCTL surface.
5. **Single-variable bypass experiments.** Change *one thing*, compare telemetry, write it down.
6. **Validate detections.** Don't just confirm your bypass — confirm what would have caught it.
7. **Write a detection pack** for what you bypassed. This is the part juniors skip and seniors don't.

If you do steps 1–7 against a single EDR for a month, you will know more about that product than 95% of red teamers do.

---

## 7. Closing

EDR is not magic and it's not invincible — but it's also not "AV with a fancier dashboard." It's a layered telemetry pipeline, and the engineering effort behind the kernel-side providers is genuinely impressive. If you walk in expecting to disable it with a one-liner, you're going to get burned.

The right mindset is: **assume telemetry is being emitted, and design tradecraft that emits the least interesting events possible**.

### Further reading

- 0xdbgman — [EDR Internals: Research & Bypass](https://0xdbgman.github.io/posts/edr-internals-research-and-bypass/) — the deep version of this post.
- MITRE ATT&CK — Defense Evasion (TA0005).
- Microsoft docs — *Filter Manager Concepts*, *Process and Thread Notification Routines*, *Microsoft-Windows-Threat-Intelligence ETW provider*.
- Outflank — *Direct Syscalls vs Indirect Syscalls*.
- Cobalt Strike blog — sleep mask / stack spoof series.
- SilentMoonwalk paper.

If you spot anything wrong here, ping me on Twitter/X — I learn this stuff the same way you do, one mistake at a time.

— Spy0x7
