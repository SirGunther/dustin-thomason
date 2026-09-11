## Install RealVisXL 5.0 into ComfyUI

### 1. Download the FP16 checkpoint

From the RealVisXL V5.0 page, choose the normal **V5.0 (BakedVAE)** version and download:

```
RealVisXL_V5.0_fp16.safetensors
```

Use **FP16**, not FP32.

The FP16 checkpoint is roughly 6.46 GB; the FP32 version is roughly twice that size. ([Civitai](https://civitai.work/models/139562/realvisxl-v50?modelVersionId=789646&utm_source=chatgpt.com "RealVisXL V5.0 - V5.0 (BakedVAE) | Stable Diffusion XL Checkpoint | Civitai"))

### 2. Put the file in ComfyUI's checkpoint folder

Move the downloaded `.safetensors` file to:

```
C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Shared\models\checkpoints
```

So you should end up with something like:

```
C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Shared\models\checkpoints\RealVisXL_V5.0_fp16.safetensors
```

That's the installation. There is no installer to run and nothing to extract.

### 3. Refresh ComfyUI

If ComfyUI is already running, refresh the model list.

You can either:

* press `R` in ComfyUI, or

* restart ComfyUI Desktop.

Then open the **Load Checkpoint** node.

Its dropdown should now contain:

```
RealVisXL_V5.0_fp16.safetensors
```

Select it.

### 4. Do not use the SDXL Refiner with it

This is the one part of your existing **SDXL Simple** workflow I would change.

RealVisXL V5.0 already has its VAE baked into the checkpoint and is intended to produce the finished image itself. You do not need to pass its output through the stock `sd_xl_refiner_1.0`.

So rather than continuing with the Base → Refiner workflow, use a normal single-checkpoint SDXL text-to-image workflow:

```
RealVisXL
   ↓
Prompt encoding
   ↓
KSampler
   ↓
VAE Decode
   ↓
Save Image
```

The easiest way to get there in ComfyUI is to open the template browser again and choose a **basic SDXL / text-to-image workflow that uses one Load Checkpoint node**, then select RealVisXL in that node.

### 5. Set the RealVisXL generation parameters

For the normal V5.0 checkpoint, the model author recommends:

**Sampler:**

```
DPM++ SDE Karras
```

with:

```
30+ steps
```

Or:

```
DPM++ 2M Karras
```

with:

```
50+ steps
```

The model is SDXL 1.0-based and lists **Clip Skip 1**. ([Civitai](https://civitai.work/models/139562/realvisxl-v50?modelVersionId=789646&utm_source=chatgpt.com "RealVisXL V5.0 - V5.0 (BakedVAE) | Stable Diffusion XL Checkpoint | Civitai"))

In ComfyUI, sampler and scheduler are usually separate controls. For the first option, set:

```
sampler_name: dpmpp_sde
scheduler: karras
steps: 30
```

For your first run, I would use:

```
Steps:      30
CFG:        5
Sampler:    dpmpp_sde
Scheduler:  karras
Denoise:    1.0
Width:      768
Height:     768
Batch:      1
```

Once we know your 1080 Ti handles that comfortably, move to **1024×1024**, because SDXL-family models are fundamentally designed around roughly that resolution.

The creator's suggested negative prompt is along the lines of:

```
worst quality, low quality, illustration, 3d, 2d, painting, cartoons, sketch
```

though you absolutely do not need to use that exact negative prompt. ([PixAI](https://pixai.art/en/model/1788796315360447043/1788796317898001009?utm_source=chatgpt.com "RealVisXL V5.0 AI Art Model | Mature Female | PixAI"))

## One thing to make sure of

If the file you are downloading right now says something like:

```
RealVisXL_V5.0_Lightning...
```

stop there, because **that is a different variant** and its settings are completely different: Lightning is intended for approximately **4–6 steps and CFG 1–2**. ([CivArchive](https://civitaiarchive.com/models/139562?modelVersionId=798204&utm_source=chatgpt.com "RealVisXL V5.0 V5.0 Lightning (BakedVAE) | CivArchive"))

If it says:

```
RealVisXL_V5.0_fp16.safetensors
```

then you're on the normal version I recommend, and the instructions above are the correct path.
