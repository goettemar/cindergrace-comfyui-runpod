# CINDERGRACE ComfyUI + Toolkit RunPod Template

> Hinweis: Dieses Repository ist ein Hobby-/Experimentierprojekt. Es handelt sich nicht um ein gewerbliches Angebot (keine Auftragsannahme, keine Garantien, kein Supportversprechen).

Minimal ComfyUI Docker Image mit dynamischer Custom Nodes Installation via Cindergrace Toolkit.

## Features

- **CUDA 12.8** - RTX 50xx (Blackwell), 40xx (Ada), A100, H100
- **Minimal Base Image** - Nur ComfyUI + Manager vorinstalliert
- **Dynamic Custom Nodes** - Nodes aus Toolkit-Config installiert (kein Image-Rebuild nötig!)
- **Auto-Update** - ComfyUI, Toolkit und Nodes werden bei jedem Start aktualisiert
- **Workflow Sync** - Workflows automatisch von Toolkit zu ComfyUI synchronisiert
- **Cindergrace Toolkit** - Model-Management im Browser

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

## Startup-Ablauf

```
[1/6] Setting up Cindergrace Toolkit...
      Clone oder Update von GitHub

[2/6] Updating ComfyUI...
      git pull + pip install requirements

[3/6] Syncing Custom Nodes...
      Nodes aus data/custom_nodes.json installieren

[4/6] Syncing Workflows...
      Workflows aus data/workflows/ nach ComfyUI kopieren

[5/6] Linking models...
      Symlinks von /workspace/models nach ComfyUI

[6/6] Starting Services...
      Toolkit auf Port 7861 (Background)
      ComfyUI auf Port 8188 (Foreground)
```

## Custom Nodes Management

Custom Nodes werden dynamisch aus dem Toolkit installiert, nicht ins Docker Image gebaut.

**Vorteile:**
- Nodes hinzufügen/entfernen ohne Image-Rebuild
- Konfiguration via Git versioniert
- Einheitliche Nodes auf allen Pods

**Nodes ändern:**
1. Toolkit öffnen → Custom Nodes Manager
2. Nodes aktivieren/deaktivieren
3. "Sync Nodes" klicken
4. Pod neustarten für permanente Änderung

**Oder via Git:**
1. `data/custom_nodes.json` im Toolkit-Repo editieren
2. Commit & Push
3. Bei Pod-Neustart werden Änderungen automatisch angewendet

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
│   ├── clip_vision/
│   ├── vae/
│   ├── diffusion_models/
│   ├── unet/
│   ├── loras/
│   ├── checkpoints/
│   ├── text_encoders/
│   └── audio_encoders/
├── input/                   # Upload Bilder (persistent)
├── output/                  # Generierte Videos (persistent)
├── ComfyUI/                 # Container (auto-updated)
│   └── custom_nodes/        # Dynamisch installiert via Toolkit
└── cindergrace_toolkit/     # Auto-cloned bei Start
    └── data/
        ├── custom_nodes.json    # Node-Definitionen
        └── workflows/           # Workflow JSON Dateien
```

## GPU Empfehlungen

| GPU | VRAM | Use Case |
|-----|------|----------|
| RTX 5090 | 32 GB | Beste Wahl für FP8/BF16 |
| RTX 4090 | 24 GB | Budget-Option |
| A100 40GB | 40 GB | Datacenter |
| A100 80GB | 80 GB | FP16 Modelle |

## Troubleshooting

### Auto-Update deaktivieren

Für schnelleren Start oder bei Update-Problemen:

```
SKIP_UPDATE=true
```

### Toolkit deaktivieren

Falls nur ComfyUI benötigt wird:

```
DISABLE_TOOLKIT=true
```

### Custom Node fehlt

1. Toolkit öffnen → Custom Nodes Manager
2. Prüfen ob Node in der Liste und aktiviert ist
3. Falls nicht: Node hinzufügen oder aktivieren
4. "Sync Nodes" klicken

### "Model not found"

- Network Volume korrekt gemountet? `ls /workspace/models/`
- Model-Namen prüfen (case-sensitive!)
- Toolkit nutzen um Modelle zu downloaden

### Out of Memory

- Kleineres Model-Set verwenden (FP8 statt BF16)
- Resolution reduzieren
- Größere GPU wählen

## Links

- [Cindergrace Toolkit](https://github.com/cindergrace/cindergrace_toolkit)
- [Docker Image (GHCR)](https://ghcr.io/goettemar/cindergrace-comfyui-runpod)
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- [Wan 2.2 Models](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged)

---

*CUDA 12.8 | Python 3.11 | PyTorch 2.9.1 | ComfyUI Latest*
