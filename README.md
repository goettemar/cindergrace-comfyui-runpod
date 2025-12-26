# CINDERGRACE ComfyUI RunPod Template

Optimiertes ComfyUI Docker Image für CINDERGRACE Video-Generierung auf RunPod.

## Features

- **CUDA 12.8** - Unterstützt RTX 50xx (Blackwell), 40xx (Ada), A100, H100
- **ComfyUI** - Neueste Version mit allen Dependencies
- **Custom Nodes** vorinstalliert:
  - ComfyUI-Manager
  - ComfyUI-WanVideoWrapper (Wan 2.2 Video)
  - ComfyUI-Florence2 (Image Analysis)
  - ComfyUI-GGUF (Quantized Models)
  - ComfyUI-VideoHelperSuite
  - ComfyUI-LTXVideo
  - ComfyUI-Impact-Pack
  - ComfyUI-Custom-Scripts
- **Automatisches Model-Linking** von Network Volume
- **FP8 optimiert** für 24-32 GB VRAM GPUs

## Quick Start

### 1. Network Volume erstellen

1. RunPod → Storage → Network Volumes → + New
2. Name: `cindergrace-models`
3. Region: Gleiche wie GPU Pod
4. Size: 100-150 GB

### 2. Modelle herunterladen

Starte einen günstigen CPU Pod mit der Network Volume und führe aus:

```bash
# Download Script holen
wget https://raw.githubusercontent.com/goettemar/cindergrace-comfyui-runpod/main/download_models.sh
chmod +x download_models.sh
./download_models.sh
```

Oder manuell:

```bash
mkdir -p /workspace/models/{clip,vae,diffusion_models,unet,loras,audio_encoders}
apt-get update && apt-get install -y aria2

# Wan 2.2 I2V (Minimal ~36 GB)
aria2c -x 16 -d /workspace/models/clip -o umt5_xxl_fp8_e4m3fn_scaled.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

aria2c -x 16 -d /workspace/models/vae -o wan_2.1_vae.safetensors "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

aria2c -x 16 -d /workspace/models/diffusion_models -o wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"

aria2c -x 16 -d /workspace/models/diffusion_models -o wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"
```

### 3. GPU Pod starten

1. Pods → + Deploy
2. Template: **CINDERGRACE ComfyUI** (oder Custom mit diesem Image)
3. GPU: RTX 4090, RTX 5090, oder A100
4. Network Volume: `cindergrace-models` anhängen
5. Deploy

### 4. CINDERGRACE verbinden

1. Pod Logs öffnen → URL kopieren: `https://<POD_ID>-8188.proxy.runpod.net`
2. CINDERGRACE → Settings → ComfyUI URL eintragen
3. Test Connection → Grün = Ready!

## Network Volume Struktur

```
/workspace/
├── models/
│   ├── clip/                    # Text Encoder
│   │   ├── umt5_xxl_fp8_e4m3fn_scaled.safetensors  (6.7 GB)
│   │   ├── clip_l.safetensors                       (235 MB)
│   │   └── t5xxl_fp16.safetensors                   (9.2 GB)
│   ├── vae/
│   │   ├── wan_2.1_vae.safetensors                  (254 MB)
│   │   └── ae.safetensors                           (335 MB)
│   ├── diffusion_models/
│   │   ├── wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors  (14.3 GB)
│   │   ├── wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors   (14.3 GB)
│   │   └── wan2.2_s2v_14B_fp8_scaled.safetensors             (16.4 GB)
│   ├── unet/
│   │   └── flux1-dev-fp8-e4m3fn.safetensors         (11.9 GB)
│   ├── loras/
│   │   └── wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors (1.2 GB)
│   └── audio_encoders/
│       └── wav2vec2_large_english_fp16.safetensors  (631 MB)
├── input/                       # Upload Bilder
└── output/                      # Generierte Videos (persistent)
```

## Model Sets

| Set | Modelle | Größe | Use Case |
|-----|---------|-------|----------|
| Minimal | Wan I2V | ~36 GB | Video aus Bildern |
| Standard | + Flux | ~58 GB | + Keyframe Generation |
| Full | + S2V | ~76 GB | + Speech to Video |

## GPU Empfehlungen

| GPU | VRAM | Preis/h | Empfehlung |
|-----|------|---------|------------|
| RTX 5090 | 32 GB | ~$0.80 | Beste Wahl für FP8 |
| RTX 4090 | 24 GB | ~$0.40 | Budget-Option |
| 2x RTX 4090 | 48 GB | ~$1.00 | Für größere Batches |
| A100 40GB | 40 GB | ~$1.50 | Datacenter |
| A100 80GB | 80 GB | ~$2.00 | FP16 Modelle |

## Docker Image bauen

### Option 1: GitHub Actions (empfohlen)

Das Image wird automatisch gebaut bei:
- **Push auf main:** Automatisch mit Tag `latest`
- **Manuell:** Actions → "Build Docker Image" → "Run workflow"
- **Release Tag:** Push mit Tag `v1.0.0`

```bash
# Release erstellen
git tag v1.0.0
git push origin v1.0.0
```

### Option 2: Lokal bauen

```bash
docker build -t ghcr.io/goettemar/cindergrace-comfyui-runpod:latest .
docker push ghcr.io/goettemar/cindergrace-comfyui-runpod:latest
```

## Template auf RunPod erstellen

1. My Templates → New Template
2. Einstellungen:
   - Name: `CINDERGRACE ComfyUI`
   - Container Image: `ghcr.io/goettemar/cindergrace-comfyui-runpod:latest`
   - Container Disk: 30 GB
   - Volume Mount Path: `/workspace`
   - HTTP Ports: `8188`
3. Optional: Public Template aktivieren
4. Save Template

## Troubleshooting

### "Connection refused" in CINDERGRACE
- Warte 1-2 Minuten bis ComfyUI gestartet ist
- Prüfe Pod Logs auf Fehler

### "Forbidden" Error
- CINDERGRACE Version aktualisieren (User-Agent Header Fix)

### "Model not found"
- Network Volume korrekt gemountet? `ls /workspace/models/`
- Model-Namen prüfen (case-sensitive!)

### Out of Memory
- Kleineres Model-Set verwenden
- Resolution reduzieren
- Größere GPU wählen

## Dateien

| Datei | Beschreibung |
|-------|--------------|
| `Dockerfile` | Docker Image Definition |
| `start.sh` | Container Startup Script |
| `link_models.sh` | Model Symlink Script |
| `download_models.sh` | Model Download Helper |
| `template.json` | RunPod Template Config |

## Links

- [CINDERGRACE GUI](https://github.com/goettemar/cindergrace-pipeline-gui)
- [Docker Image (GHCR)](https://ghcr.io/goettemar/cindergrace-comfyui-runpod)
- [RunPod Docs](https://docs.runpod.io)
- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [Wan 2.2 Models](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged)

---

*CUDA 12.8 | Python 3.11 | PyTorch 2.x | ComfyUI Latest*
