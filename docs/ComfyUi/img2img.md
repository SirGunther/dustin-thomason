Absolutely. Here’s a **quickstart guide** you can save as-is. I’ll keep it simple and focused on the exact thing we just did.

# Quickstart: ComfyUI Img2Img (whole-image transformation)

This is for the case where you want to:

* load an existing image

* transform the **entire image**

* guide the transformation with a prompt

This is **img2img**, not inpainting.

---

## What changes from text-to-image

A normal text-to-image workflow uses:

```
Empty Latent Image → KSampler
```

For img2img, replace that with:

```
Load Image → VAE Encode → KSampler
```

That is the main change.

---

## Node wiring

If you already have a working workflow with your checkpoint loaded, wire it like this:

### Keep these connections

```
Load Checkpoint MODEL → KSampler model
Load Checkpoint CLIP → Prompt encoding nodes
KSampler output → VAE Decode samples
Load Checkpoint VAE → VAE Decode vae
```

### Replace the latent source

Disconnect:

```
Empty Latent Image → KSampler latent_image
```

Then add these nodes:

* **Load Image**

* **VAE Encode**

And connect them like this:

```
Load Image IMAGE → VAE Encode pixels
Load Checkpoint VAE → VAE Encode vae
VAE Encode LATENT → KSampler latent_image
```

So the full idea becomes:

```
Load Checkpoint
 ├─ MODEL → KSampler
 ├─ CLIP  → Prompt nodes
 └─ VAE   → VAE Encode and VAE Decode

Load Image → VAE Encode → KSampler → VAE Decode → Save/Preview
```

---

## What each node is doing

* **Load Image** = your starting image

* **VAE Encode** = converts that image into latent space

* **KSampler** = transforms that latent using your prompt

* **VAE Decode** = turns the result back into a visible image

---

## Important note about KSampler Advanced

In **KSampler (Advanced)**, there is no single field called `denoise`.

Instead, the amount of change is controlled primarily by:

* **steps**

* **start_at_step**

* **add_noise** should be **enabled**

So:

* **lower `start_at_step`** = more change

* **higher `start_at_step`** = less change

`cfg` is **not** denoise.
`cfg` controls how strongly the model follows the prompt.

---

## Denoise conversion rule

Use this formula:

```
effective denoise ≈ 1 - (start_at_step / total_steps)
```

Or if you want to work backward:

```
start_at_step ≈ total_steps × (1 - desired denoise)
```

Round to the nearest whole number.

---

## Simple cheat sheet

### If total steps = 20

* `start_at_step = 0` → denoise `1.0` → almost full remake

* `start_at_step = 4` → denoise `0.8` → strong change

* `start_at_step = 8` → denoise `0.6` → fairly strong change

* `start_at_step = 10` → denoise `0.5` → medium change

* `start_at_step = 14` → denoise `0.3` → light change

* `start_at_step = 16` → denoise `0.2` → subtle change

### If total steps = 30

* `start_at_step = 0` → denoise `1.0`

* `start_at_step = 6` → denoise `0.8`

* `start_at_step = 12` → denoise `0.6`

* `start_at_step = 15` → denoise `0.5`

* `start_at_step = 21` → denoise `0.3`

* `start_at_step = 24` → denoise `0.2`

### If total steps = 6\` (good for Lightning-style models)

* `start_at_step = 0` → denoise `1.0`

* `start_at_step = 1` → denoise `0.83`

* `start_at_step = 2` → denoise `0.67`

* `start_at_step = 3` → denoise `0.50`

* `start_at_step = 4` → denoise `0.33`

* `start_at_step = 5` → denoise `0.17`

Because 6-step workflows are so short, the denoise control is more coarse.

---

## Practical interpretation

Use this as the quick mental guide:

* **denoise 0.2–0.3** = subtle restyle, preserve most of image

* **denoise 0.4–0.6** = moderate transformation

* **denoise 0.7–0.9** = strong transformation

* **denoise 1.0** = almost a full remake from the source image

---

## Suggested starting settings

### For a normal non-Lightning checkpoint

Start with:

```
Steps: 20
CFG: 5 to 7
Sampler: dpmpp_sde
Scheduler: karras
add_noise: enable
start_at_step: 10
```

That gives you roughly **denoise 0.5**, which is a good medium img2img test.

### For a Lightning-style checkpoint

Start with:

```
Steps: 6
CFG: 1.5
Sampler: dpmpp_sde
Scheduler: karras
add_noise: enable
start_at_step: 2 or 3
```

That gives you a moderate transformation.

---

## Easy starting presets

### Subtle change

For a source image you want to mostly preserve:

* 20-step workflow: `start_at_step = 14 to 16`

* 6-step workflow: `start_at_step = 4`

### Medium change

For “keep the structure, but noticeably transform it”:

* 20-step workflow: `start_at_step = 8 to 10`

* 6-step workflow: `start_at_step = 2 to 3`

### Strong change

For “use this image as a base, but remake it heavily”:

* 20-step workflow: `start_at_step = 0 to 4`

* 6-step workflow: `start_at_step = 0 to 1`

---

## Minimal workflow summary

If you want the shortest possible reminder, this is it:

### Text-to-image

```
Empty Latent Image → KSampler
```

### Img2img

```
Load Image → VAE Encode → KSampler
```

### KSampler Advanced rule

```
More change = lower start_at_step
Less change = higher start_at_step
```

### Conversion rule

```
denoise ≈ 1 - (start_at_step / steps)
```

---

## Recommended first test

If you want a good first whole-image transformation test, use:

### Normal checkpoint

* `steps = 20`

* `start_at_step = 10`

* `cfg = 6`

### Lightning checkpoint

* `steps = 6`

* `start_at_step = 2`

* `cfg = 1.5`

Then give it a prompt like:

```
a cinematic version of this image, dramatic lighting, highly detailed, realistic
```

---

If you want, I can next make you a **second quickstart just for masking/inpainting**, in the exact same compact format.
