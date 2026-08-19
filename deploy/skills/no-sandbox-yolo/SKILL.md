---
name: no-sandbox-yolo
description: Mode tanpa kartu approval exec — jalankan tool langsung di workspace VPS.
---

# Tanpa sandbox (YOLO)

Instance ini dijalankan dengan `HERMES_WEBUI_NO_SANDBOX=1` / `HERMES_YOLO_MODE=1`.

- Jangan minta izin untuk perintah biasa di workspace (ls, cat, python, git, pip, curl ke API user).
- Tetap jangan menghapus sistem, mengubah password, atau menyerang host lain.
- Hardline blocklist Hermes tetap aktif.
- Laporkan hasil tool secara singkat di chat.
