# ZERO-LINE environment snapshot

Restorable project workspace archive, published at the user's explicit request.
The playable source branch is `zero-line-prototype`; read `NEXT_AI_HANDOFF.md` there first.
This branch preserves external model intakes, original uploads, build outputs, diagnostic captures, reports, scripts and source working files from `/workspace`.

Installed tools/virtual environments, Git history, Godot caches, dependency caches, credential files and runtime sockets are excluded. See inventory.json for exact captured paths and exclusions. Tools can be reinstalled; this is a project workspace backup, not a machine image.

Restore into an empty directory (archive contains original workspace-relative paths):

```sh
sha256sum -c SHA256SUMS
cat workspace.tar.gz.part* | tar -xz -C /path/to/restore
```

The inventory and checksums must be present in the final commit. A branch without SHA256SUMS is still uploading. Chunk ordering is lexical, four digit zero-padded. No frame-time or visual approval is implied by preserving diagnostic artifacts.
