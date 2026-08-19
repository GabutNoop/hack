---
name: skill-creator
description: Buat skill Hermes baru (SKILL.md) yang bisa dipakai ulang di chat berikutnya.
---

# Skill creator

Saat user minta alur kerja yang akan diulang, tulis skill baru di `$HERMES_HOME/skills/<slug>/SKILL.md`.

Isi minimal:

```yaml
---
name: slug-pendek
description: satu kalimat kapan skill ini dipakai
---
```

Lalu langkah konkret, perintah, dan kriteria selesai. Jangan simpan API key di skill. Setelah menulis, sebut path file-nya ke user.
