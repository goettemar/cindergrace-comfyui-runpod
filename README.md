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

Nutze das **CINDERGRACE Model Manager** Template (CPU Pod) um Modelle zu downloaden:

1. Model Manager Template deployen (siehe unten)
2. Web UI öffnen
3. Quick Links Tab → URLs kopieren und downloaden

Oder manuell per SSH:

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

## RunPod Template Einstellungen

| Feld | Wert |
|------|------|
| **Template Name** | CINDERGRACE ComfyUI |
| **Container Image** | `ghcr.io/goettemar/cindergrace-comfyui-runpod:latest` |
| **Container Disk** | 30 GB |
| **Volume Mount Path** | `/workspace` |
| **HTTP Port** | `8188` |

### Template README (für RunPod):
```
CINDERGRACE ComfyUI - Video Generation Backend

Optimized for AI video generation with CINDERGRACE Pipeline GUI.

INCLUDED:
• CUDA 12.8 + PyTorch 2.9.1 (RTX 50xx/40xx/A100 ready)
• ComfyUI with Manager
• Wan 2.2, Flux, LTX-Video, Florence-2, GGUF support

SETUP:
1. Attach Network Volume with models at /workspace
2. Deploy GPU pod (RTX 4090/5090 recommended)
3. Copy proxy URL: https://<POD_ID>-8188.proxy.runpod.net
4. Paste into CINDERGRACE → Settings → ComfyUI URL

MODELS:
Use "CINDERGRACE Model Manager" template to download models.

LINKS:
• GitHub: https://github.com/goettemar/cindergrace-comfyui-runpod
• Discord: Coming soon
• Docs: https://github.com/goettemar/cindergrace_gui
```

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
│   │   └── flux1-krea-dev.safetensors                        (~24 GB)
│   ├── unet/
│   ├── loras/
│   └── audio_encoders/
├── input/                       # Upload Bilder
└── output/                      # Generierte Videos (persistent)
```

## Model Sets

| Set | Modelle | Größe | Use Case |
|-----|---------|-------|----------|
| Minimal | Wan I2V | ~36 GB | Video aus Bildern |
| Standard | + Flux | ~60 GB | + Keyframe Generation |
| Full | + S2V | ~76 GB | + Speech to Video |

## GPU Empfehlungen

| GPU | VRAM | Preis/h | Empfehlung |
|-----|------|---------|------------|
| RTX 5090 | 32 GB | ~$0.80 | Beste Wahl für FP8 |
| RTX 4090 | 24 GB | ~$0.40 | Budget-Option |
| A100 40GB | 40 GB | ~$1.50 | Datacenter |
| A100 80GB | 80 GB | ~$2.00 | FP16 Modelle |

## Troubleshooting

### "Connection refused" in CINDERGRACE
- Warte 1-2 Minuten bis ComfyUI gestartet ist
- Prüfe Pod Logs auf Fehler

### "Forbidden" (403) Error
- CINDERGRACE Version aktualisieren (User-Agent Header Fix)

### "Model not found"
- Network Volume korrekt gemountet? `ls /workspace/models/`
- Model-Namen prüfen (case-sensitive!)

### Out of Memory
- Kleineres Model-Set verwenden
- Resolution reduzieren
- Größere GPU wählen

## Links

- [CINDERGRACE GUI](https://github.com/goettemar/cindergrace_gui)
- [CINDERGRACE Model Manager](https://github.com/goettemar/cindergrace-model-manager)
- [Docker Image (GHCR)](https://ghcr.io/goettemar/cindergrace-comfyui-runpod)
- [RunPod Docs](https://docs.runpod.io)
- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [Wan 2.2 Models](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged)
- Discord: Coming soon

---

*CUDA 12.8 | Python 3.11 | PyTorch 2.9.1 | ComfyUI Latest*
