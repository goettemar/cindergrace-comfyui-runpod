# CINDERGRACE ComfyUI + Toolkit RunPod Template

Optimiertes ComfyUI Docker Image mit integriertem Cindergrace Toolkit fuer RunPod.

## Features

- **CUDA 12.8** - RTX 50xx (Blackwell), 40xx (Ada), A100, H100
- **Auto-Update** - ComfyUI und Custom Nodes werden bei jedem Start aktualisiert
- **Cindergrace Toolkit** - Automatisch installiert, Model-Management im Browser
- **Custom Nodes** vorinstalliert:
  - ComfyUI-Manager
  - ComfyUI-WanVideoWrapper (Wan 2.2 Video)
  - ComfyUI-Florence2 (Image Analysis)
  - ComfyUI-GGUF (Quantized Models)
  - ComfyUI-VideoHelperSuite
  - ComfyUI-LTXVideo
  - ComfyUI-Impact-Pack
  - ComfyUI-Custom-Scripts

## Quick Start

### 1. Network Volume erstellen

1. RunPod → Storage → Network Volumes → + New
2. Name: `cindergrace-models`
3. Region: Gleiche wie GPU Pod
4. Size: 100-150 GB

### 2. Pod starten

1. Pods → + Deploy
2. Template: **CINDERGRACE ComfyUI + Toolkit**
3. GPU: RTX 4090, RTX 5090, oder A100
4. Network Volume: `cindergrace-models` anhängen
5. Deploy

### 3. Services nutzen

Nach dem Start sind zwei Services verfügbar:

| Service | URL | Port |
|---------|-----|------|
| **ComfyUI** | `https://<POD_ID>-8188.proxy.runpod.net` | 8188 |
| **Toolkit** | `https://<POD_ID>-7861.proxy.runpod.net` | 7861 |

## Environment Variables

| Variable | Default | Beschreibung |
|----------|---------|--------------|
| `SKIP_UPDATE` | `false` | `true` = Kein Auto-Update (schnellerer Start) |
| `DISABLE_TOOLKIT` | `false` | `true` = Toolkit nicht starten |

## RunPod Template Einstellungen

| Feld | Wert |
|------|------|
| **Template Name** | CINDERGRACE ComfyUI + Toolkit |
| **Container Image** | `ghcr.io/goettemar/cindergrace-comfyui-runpod:latest` |
| **Container Disk** | 30 GB |
| **Volume Mount Path** | `/workspace` |
| **HTTP Ports** | `8188, 7861` |

## Network Volume Struktur

```
/workspace/
├── models/                  # Network Volume (persistent)
│   ├── clip/
│   ├── vae/
│   ├── diffusion_models/
│   ├── unet/
│   ├── loras/
│   ├── checkpoints/
│   └── audio_encoders/
├── input/                   # Upload Bilder (persistent)
├── output/                  # Generierte Videos (persistent)
├── ComfyUI/                 # Container (auto-updated)
└── cindergrace_toolkit/     # Auto-cloned bei Start
```

## Startup-Ablauf

```
[1/4] Updating ComfyUI...
      git pull + pip install requirements

[2/4] Updating custom nodes...
      Alle Nodes mit git pull aktualisieren

[3/4] Setting up Cindergrace Toolkit...
      Clone oder Update von GitHub

[4/4] Linking models...
      Symlinks von /workspace/models nach ComfyUI

Starting Services:
  - Toolkit auf Port 7861 (Background)
  - ComfyUI auf Port 8188 (Foreground)
```

## GPU Empfehlungen

| GPU | VRAM | Use Case |
|-----|------|----------|
| RTX 5090 | 32 GB | Beste Wahl fuer FP8 |
| RTX 4090 | 24 GB | Budget-Option |
| A100 40GB | 40 GB | Datacenter |
| A100 80GB | 80 GB | FP16 Modelle |

## Troubleshooting

### Auto-Update deaktivieren

Fuer schnelleren Start oder bei Update-Problemen:

```
SKIP_UPDATE=true
```

### Toolkit deaktivieren

Falls nur ComfyUI benoetigt wird:

```
DISABLE_TOOLKIT=true
```

### "Model not found"

- Network Volume korrekt gemountet? `ls /workspace/models/`
- Model-Namen pruefen (case-sensitive!)
- Toolkit nutzen um Modelle zu downloaden

### Out of Memory

- Kleineres Model-Set verwenden (FP8 statt BF16)
- Resolution reduzieren
- Groessere GPU waehlen

## Links

- [Cindergrace Toolkit](https://github.com/cindergrace/cindergrace_toolkit)
- [Docker Image (GHCR)](https://ghcr.io/goettemar/cindergrace-comfyui-runpod)
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- [Wan 2.2 Models](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged)

---

*CUDA 12.8 | Python 3.11 | PyTorch 2.9.1 | ComfyUI Latest*
