# Everest Connect IQ — hardening pass 2

Target: Garmin Edge 840. This pass preserves the existing data-field design and notifications while adding conservative recovery and GPS-transition safeguards. It has **not** been compiled or tested on a Garmin device because the Connect IQ SDK / `monkeyc` compiler is unavailable in this environment.

## Changes in this pass

- **Persist completed challenge progress** using `Toybox.Application.Storage`: completed ascent/descent durations and completed summit count are stored on state transitions and at roughly 60 seconds of activity elapsed time. Storage failures are caught and never interrupt live tracking.
- **Resume within the same activity:** on a data-field restart, previously completed laps are restored and the in-progress segment state returns to `INIT`. This intentionally avoids replaying a stale GPS transition or restoring a stale `Activity.Info` object.
- **Reset for a new activity:** elapsed activity time moving backwards by more than five seconds relative to the last persisted checkpoint clears the stored challenge snapshot. This is a best-effort discriminator because Connect IQ data fields do not expose a universal activity/session identifier in this code path.
- **GPS debouncing:** transitions now require two consecutive fixes proposing the same transition. This filters single-fix boundary spikes with approximately one update interval of additional latency. Existing ascent/descent notifications and milestone sounds remain in place.
- **Count summit completions independently from timing:** a summit transition increments the completed ascent count even if elapsed-time data is missing or invalid; only valid positive durations enter the timing statistics.
- **Restore timing summaries:** persisted ascent/descent means and min/max values are recalculated from the stored completed lap arrays and the corresponding FIT fields are rehydrated when possible.
- **Validate user settings:** invalid ascent targets, ascent heights, radii, and impossible degree/radian coordinates fall back to conservative defaults rather than causing invalid divisions or startup failures. Default segment coordinates are used if coordinates are outside the selected degree/radian range.
- **Reduce diagnostic overhead:** property reads no longer emit a log line every time they are accessed.

## Important assumptions and limitations

1. The session reset heuristic compares activity elapsed time with the last checkpoint. It is robust for ordinary new activities after a longer ride, but cannot perfectly distinguish two activities if the previous activity ended before its first useful checkpoint or the device reports elapsed time unexpectedly. Verify with actual Edge 840 lifecycle behavior.
2. Persistence uses `Application.Storage` and nested arrays/dictionaries. Confirm the target SDK accepts this exact storage payload and size. If storage limits are lower than expected, replace full lap arrays with bounded aggregates (count, sum, min, max, last) or a capped history.
3. Only completed lap statistics are persisted. An in-progress ascent/descent is intentionally restarted in `INIT` after a data-field restart; its partial duration is not counted.
4. Two-fix debounce adds delay. Test at the configured radius and adjust if short summit visits are missed. The current approach confirms transitions at both the inside/outside boundaries, not just summit arrivals.
5. The GPS coordinate fallback assumes the built-in default segment is acceptable if user coordinates are invalid. If the user changes GPS format, confirm that coordinate settings are entered in that format; degrees remain the recommended/default setting.
6. Existing notifications and milestone sounds are retained. Battery impact has not been measured. This code does not request a second GPS source; storage writes occur on transitions and at most roughly once per elapsed minute.
7. FIT field availability, `Application.Storage` API compatibility, and Monkey C typing still need SDK validation.

## Required validation

- Compile for `edge840` using the current Connect IQ SDK.
- Test bottom → ascent → top → descent → bottom, with a single GPS spike at each boundary and repeated jitter across the configured radius.
- Restart the data field during an activity and confirm completed count, means, min/max, and progress are restored without duplicating a lap.
- Start a new activity and confirm the prior challenge snapshot resets.
- Test pause/auto-pause/resume and missing GPS fixes.
- Test invalid settings: target 0/negative/very large, ascent height 0/negative, radius 0/very large, and invalid top/bottom coordinates.
- Record a long activity and inspect FIT fields, notifications, storage behavior, and battery use on the Edge 840.
