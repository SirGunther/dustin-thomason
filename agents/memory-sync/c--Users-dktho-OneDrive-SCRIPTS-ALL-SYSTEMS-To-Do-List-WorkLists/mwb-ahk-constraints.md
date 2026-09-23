---
name: mwb-ahk-constraints
description: Why AutoHotkey gestures stop relaying across Mouse Without Borders (hook install order) and the confirmed fix; plus the work-machine compile constraint
metadata: 
  node_type: memory
  type: project
  originSessionId: 86df1c60-3ebc-4204-a7ec-c6f8f647e83a
  modified: 2026-08-10T20:28:13.592Z
---

The user runs the SAME AutoHotkey scripts on multiple machines and drives the
secondary ones with **Mouse Without Borders — the standalone Microsoft Garage
build 2.2.1.327**, at `C:\Program Files (x86)\Microsoft Garage\Mouse without
Borders\`. **Not the PowerToys module; PowerToys is not installed.** Processes:
`MouseWithoutBorders.exe`, `MouseWithoutBordersHelper.exe`.

## 1. The recurring failure: hook install order (CONFIRMED 2026-08-10)

**Symptom triad:** the gesture works fine on each machine tested locally, does
nothing on the remote machine through MWB, and used to work with no script
change — sometimes returning on its own after a restart.

**Cause:** Windows calls `WH_KEYBOARD_LL` hooks in **reverse install order** —
most recently installed runs first. The scripts use CapsLock as a combo prefix
(and `SCRIPTS ALL SYSTEMS.ahk` sets `SetCapsLockState, AlwaysOff`), so AHK
**consumes** CapsLock. That is correct and desirable locally. But when AHK's
hooks are installed *after* MWB's, AHK runs *first* and eats CapsLock before
MWB's hook sees it — MWB has no prefix to relay, and the remote machine gets a
bare click. Hook order follows process start order, which varies per boot, so it
looks random.

**FIX (confirmed by the user — this was the entire solution): restart Mouse
Without Borders on EACH system**, after the AHK scripts are already running.
Reinstalls MWB's hook last, putting it ahead of AHK. No script edit, no
recompile, no config change.

Evidence pattern that confirms it before touching anything: compare
`CreationDate` of `MouseWithoutBorders*` vs `AutoHotkey*` processes
(`Get-CimInstance Win32_Process`). MWB earlier than the scripts ⇒ relay broken.

Durable option if the restart gets tiresome: launch MWB *after* the script set
instead of at boot.

**Full writeup lives with the code:** `SCRIPTS ALL SYSTEMS\Move Windows - Click
Drag Resize Close - README.md` — includes the symptom triad, the fix, the
diagnostic commands, and a "do not re-investigate these" list.

## 2. CORRECTION — a previous version of this memory was wrong

It claimed MWB relays keyboard and mouse as two separate streams and therefore
`CapsLock & LButton` / `Ctrl & LButton` **cannot** cross MWB, and that the
"Ctrl latch" was the necessary workaround. **That conclusion is wrong.**
`CapsLock & LButton` crosses MWB fine once MWB's hook is ahead of AHK's. Acting
on the old claim caused a wasted session: it led to proposing a redesign of a
working gesture and to editing a working file on an unconfirmed theory.

The two-stream architecture is real, but the operative failure is **hook order**,
not a cross-stream limitation. Do not use the stream theory to justify
redesigning gestures.

The Ctrl latch blocks in the script are **deliberately commented out and are
kept as history**. The script works as written. **Never re-enable them as a
"fix," and never delete them.**

## 3. Still-valid technical constraints

- **MWB-injected mouse buttons read UP in BOTH logical and physical
  `GetKeyState`** on the receiving machine. So never *poll* the button to decide
  whether a drag is still active — a polling loop exits instantly (`iters=1`).
  Use an event-driven button-up hotkey, which does fire for injected input.
- Button-up detectors must be `#If`-gated on a flag and **not** `~`, so the
  release is swallowed mid-gesture (a global `~*RButton Up::` leaks the release
  and pops a context menu during a resize).
- A Ctrl-release "safety" break must be gated to Ctrl-initiated drags, or it
  instantly kills CapsLock drags (with no Ctrl held, "Ctrl released" is always
  true).
- `KDE_MWBGuard` suspends the local copy while an MWB helper window is active,
  so each machine only acts when the cursor is on it. Timers keep running during
  `Suspend`, which is what lets it self-resume.

## 4. Work machine

The work computer **requires compiling .ahk to .exe**. Logic is identical to the
`.ahk` — the only difference is that it's compiled. A source change does not
reach it until the `.exe` is rebuilt **there**. On-screen debug output isn't
practical on it, so diagnostics should log to a file in the OneDrive-synced
SCRIPTS folder to sync back. Prefer fixes verifiable by real behavior (does the
window move?) over ones needing values read back.

## 5. Ground rule

"Works on each machine independently" and "works across MWB" are **different
claims** and have failed independently. When the relay breaks, **suspect the
environment (hook order, process start order, MWB's own state) before the
script.** The script has been correct as written every time so far. See
[[dont-edit-working-files-on-unconfirmed-theory]].
