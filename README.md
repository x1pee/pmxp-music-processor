---
title: PMXP Claimed Music Processor
emoji: 🎵
colorFrom: blue
colorTo: gray
sdk: docker
app_port: 7860
---

Owner-operated Python/FFmpeg processor for PMXP. Sites retains authenticated Mini App state, claims, queue, preferences and durable delivery fences. This service executes only a claimed job pushed by Sites. It never polls Telegram, discovers old queues, imports historical jobs, starts the original service or automatically sends on startup.

The source is a narrow adaptation of the owner's retained PMXP Music Bot runtime. `SOURCE-PROVENANCE.json` pins original and adapted modules. No private snapshots, audio files, user history, tokens or old work caches belong in this repository/image. Use the owner's code only for this service; third-party `yt-dlp` and FFmpeg retain their own licenses.

Runtime secrets must be configured in the hosting dashboard, not Git/build arguments:

- `MINI_PROCESSOR_SECRET`: newly generated 64 lowercase hex characters, shared only with Sites.
- `TELEGRAM_BOT_TOKEN`: current owned bot token.
- `SITE_ORIGIN`: exactly `https://pmxp.fun`.
- `PORT`: platform port (default 7860); `PMP_RUNTIME_ROOT`: ephemeral writable directory outside `/app`.

One job worker and capacity three (one running plus two queued) are used for the free 512 MB Render service. Conversion/download/provider concurrency is reduced; downloads and FFmpeg retain the original fixed-code timeouts and file limits. This is a best-effort memory target, not an observed production memory measurement. Idle/cold-start hosting behavior is handled by Sites retries with the same claim; a sleeping service does not imply a completed job.

`GET /health` returns protocol/worker/active counts only. `POST /jobs/start` requires `Authorization: Bearer <MINI_PROCESSOR_SECRET>`, JSON content type, maximum 2 MiB and the exact body:

```json
{"id":"already_claimed_job_id","type":"search","input":{"query":"artist title","provider":"SoundCloud"},"claim":"already-issued-opaque-claim","userId":1807122506,"created":1790000000000}
```

`created` is optional. Supported types: `search` (including albums/alternative), `discover`, `catalogue`, `audit`, `prepare`, `send`, `playlist`. Input matches the original worker; playlists request their private plan through the callback. Optional `input.context` holds a bounded owner profile and minimal artist catalogue supplied by Sites. No caller filesystem/command/proxy/callback URL is accepted. Discovery uses the claimed `input.profile`, including preferences/exclusions/history. The processor never calls Beget or a public profile endpoint.

202 means accepted or exact duplicate, 409 means same id with changed claim/core payload, 503 means bounded capacity. Volatile owner context and refreshed discovery profile are excluded from the canonical duplicate fingerprint; the first accepted payload is retained. A 202 does not mean completed. An in-memory registry prevents replay in this process; Sites' durable one-use fence prevents duplicate sends across process restarts. No public status endpoint exposes jobs.

Callbacks are POSTs only to `https://pmxp.fun/api/mini/processor/{renew,progress,partial,delivered,complete,playlist}`, authenticated with the same secret and body `{id,token:claim,...originalFields}`. A legacy playlist button token is sent as `deliveryToken`. A stale claim returns 409. Immediately before a Telegram audio send/media replacement the processor consumes `renew {deliveryFence:true,deliveryKey:"send"}` (playlist keys `playlist:0:send`, etc.). A missing/lost fence response stops the send. Every actual send requires a positive Telegram message id. Single sends immediately report the private audio receipt through `delivered`; playlists use the original per-card `playlist activate` receipt, never the single-message delivered callback. A lost/ambiguous Telegram result is marked uncertain and is never automatically resent. Even a definitive rejection conservatively requires a fresh user job; automatic retry cannot consume another fence. Telegram errors and request bodies are not logged.

Ephemeral work caches are expendable; Sites is the system of record. A restart may discard prepared files but cannot authorize another send using a consumed fence. The original FFmpeg local input protocol whitelist (`file,pipe`) and demuxer limits are preserved. Python network guards reject private/reserved destinations at DNS resolution and socket connect, including provider subprocesses and redirects; provider URL allowlists further bound input.

Run isolated tests with `python -B -m unittest discover -s tests -v` with `TEMP`/`TMP` on the intended local work drive. Tests replace callbacks/providers/Telegram and block all network. A successful test is synthetic code QA; it does not prove Docker build, Render deployment, provider availability, Telegram delivery or real-device Mini App behavior.

Docker uses non-root uid 1000. For Hugging Face Docker compatibility the README exposes port 7860; secrets are runtime environment variables, and local disk is ephemeral ([official Docker Spaces documentation](https://huggingface.co/docs/hub/spaces-sdks-docker)). Render may set `PORT`; the process binds `0.0.0.0` at that value. Deploy only this sanitized directory. The final publication and live no-send health checks are performed separately by the owner-controlled deployment workflow.


The complete audited source tree is in `processor-source.tar.gz` (SHA256 `f9a8664c19de1b8d0bcec6af8fef47a1f01f6020c1c7f6fcfa22dd49a78e99f1`). The Docker build verifies the archive before extraction. No runtime credentials or private application data are included.
