# README.md

## Overview

This assignment implements a reusable `CameraSession` module designed as a lightweight SDK component. The focus was on clean API design, correct AVFoundation usage, and strict adherence to threading constraints rather than building a full-featured camera application.

---

## Design Decisions

### 1. Separation of Concerns

The public API (`CameraSession`) is intentionally minimal:

* `configure(resolution:fps:)`
* `start()`
* `stop()`
* Delegate for frame delivery

All AVFoundation-specific logic is encapsulated internally, ensuring that SDK consumers interact with a simple and stable interface.

---

### 2. Threading Model

* A private serial queue (`sessionQueue`) is used for all `AVCaptureSession` operations.
* This ensures:

  * Thread safety
  * No blocking of the main thread
  * Deterministic session behavior

The delegate callback is dispatched onto a configurable `delegateQueue`, defaulting to `DispatchQueue.main`.

This design allows flexibility for SDK consumers:

* UI apps → main queue
* ML pipelines → background queue

---

### 3. Why not use Main Thread?

AVFoundation is not thread-safe when used on arbitrary queues. Running capture operations on the main thread can:

* Block UI rendering
* Cause frame drops
* Introduce race conditions

Using a dedicated serial queue ensures predictable execution.

---

### 4. Format Selection Strategy

Instead of relying solely on `sessionPreset`, the implementation iterates over `AVCaptureDevice.formats` and their supported frame rate ranges.

This is necessary because:

* `sessionPreset` does NOT guarantee FPS
* FPS must be explicitly configured via `activeFormat` and frame duration

Trade-off:

* Slightly more complex logic
* Much higher correctness and control

---

### 5. Error Handling

If no compatible format is found, the system throws:

```
CameraSessionError.unsupportedFormat
```

The error includes the requested FPS to improve debuggability.

---

### 6. Delegate Design

The delegate pattern is used to:

* Decouple frame production from consumption
* Avoid tight coupling with UI or processing logic

The delegate is weak to prevent retain cycles.

---

### 7. Objective-C Shim (Singleton Design)

The C-callable shim exposes:

* `camera_start()`
* `camera_stop()`

It internally uses a singleton `CameraSession`.

#### Trade-offs:

* Simple integration for C/C++ consumers
* Not scalable for multiple camera sessions
* Cannot support multi-camera or concurrent pipelines

At scale, this design would fail in:

* Multi-stream AR systems
* Parallel video processing pipelines

A better approach would be instance-based management.

---

### 8. Unit Testing Decisions

#### Test 1: Unsupported FPS

Ensures that invalid configurations fail correctly.

#### Test 2: Delegate Queue Validation

Uses `dispatchPrecondition(condition: .onQueue(...))` instead of `Thread.isMainThread`.

#### Why not Thread.isMainThread?

* `Thread.isMainThread` only checks if execution is on main thread
* `dispatchPrecondition` verifies execution on a specific queue

This is critical because:

* A non-main queue is still incorrect if it’s not the intended queue

---

## Trade-offs

| Decision         | Benefit              | Drawback            |
| ---------------- | -------------------- | ------------------- |
| Serial queue     | Thread safety        | Slight complexity   |
| Format iteration | Accurate FPS control | More code           |
| Delegate pattern | Flexibility          | Requires user setup |
| Singleton shim   | Simplicity           | Not scalable        |

---

## What I Would Improve

Given more time:

1. Add support for:

   * Camera switching (front/back)
   * Orientation handling

2. Improve format selection:

   * Match resolution + FPS more precisely

3. Add better lifecycle management:

   * Handle interruptions (calls, backgrounding)

4. Add more tests:

   * Start/stop idempotency
   * Reconfiguration safety

---

## Conclusion

The implementation prioritizes correctness, modularity, and clarity over feature completeness. The goal was to simulate a production-ready SDK component that can be safely integrated into larger systems.
