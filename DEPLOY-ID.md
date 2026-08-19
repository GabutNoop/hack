# Hermes resmi + custom API (VPS)

Repo ini adalah **Hermes WebUI resmi** ([nesquena/hermes-webui](https://github.com/nesquena/hermes-webui)) yang memakai **Hermes Agent resmi** ([NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)). Bukan mashup backend ringan.

## Ganti API / API key di web

1. Buka **Settings → Providers** (Control Center).
2. Tambah / edit **Custom OpenAI-compatible**:
   - **Name** — mis. `bandel`, `openai`, `vllm`
   - **Base URL** — harus berakhiran `/v1` (contoh `https://bandelbanget.xyz/v1`)
   - **API key**
   - **Model** — id model di endpoint itu
3. Pilih model di footer composer. Named custom muncul sebagai `custom:<nama>`.

Onboarding **Custom OpenAI-compatible** sudah di-default ke Bandel (`glm-5.3`).

## Tanpa sandbox (YOLO)

Di `.env` / `deploy.sh`:

```
HERMES_WEBUI_NO_SANDBOX=1
HERMES_YOLO_MODE=1
HERMES_EXEC_ASK=0
```

Agent tidak memaksa kartu approval exec. Blocklist perintah berbahaya Hermes tetap aktif.

## Deploy di VPS

Agent **tidak** ikut di git (terlalu besar). `deploy.sh` meng-clone ke `~/.hermes/hermes-agent`.

Di VPS (user `ubuntu`, **tanpa sudo**):

```bash
cd ~/hack   # atau path clone repo ini
git fetch origin
git checkout arena/01a01acd-hack
git pull origin arena/01a01acd-hack
bash deploy.sh
```

Lalu buka `http://202.155.143.143:8787` dan hard-refresh browser.

Cek status:

```bash
./ctl.sh status
./ctl.sh logs --no-follow --lines 80
```

Override endpoint:

```bash
BANDEL_BASE_URL=https://host-lain/v1 BANDEL_API_KEY=sk-xxx BANDEL_MODEL=nama-model bash deploy.sh
```
