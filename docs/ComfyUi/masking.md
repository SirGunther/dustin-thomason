Absolutely. Here’s the matching **quickstart for masking / inpainting** in the same simple format.

# Quickstart: ComfyUI Inpainting (masked editing)

This is for the case where you want to:

* load an existing image

* change **only part** of the image

* protect the rest of the image

* use a prompt to describe what should appear in the changed area

This is **inpainting**, not full img2img.

---

## What inpainting does

Use inpainting when you want to:

* remove an object

* replace part of a background

* change clothing or hair

* fix one region of an image

* regenerate a selected area while preserving everything else

The key idea is:

* **masked area** = change this

* **unmasked area** = keep this

---

## Basic workflow idea

A normal img2img workflow transforms the whole image.

An inpainting workflow transforms only the masked part.

Conceptually, it looks like this:

```
Load Image + Load/Create Mask → Inpaint Encode → KSampler → Decode → Save
```

The exact node names can vary a little depending on the workflow/template, but the logic is always the same:

1. load the source image

2. load or paint a mask

3. encode both together

4. sample with the prompt

5. decode and save the result

---

## What the mask means

Usually:

* **white** = regenerate this area

* **black** = preserve this area

So if you paint over a person’s shirt in white, the model will change the shirt and try to keep the rest of the image intact.

---

## Main things you need

For inpainting, you generally need:

* a **source image**

* a **mask**

* a **checkpoint/model**

* a **prompt**

* a **sampler**

* a **denoise strength** or equivalent

---

## The practical difference from full img2img

### Full img2img

```
Load Image → VAE Encode → KSampler
```

### Inpainting

```
Load Image + Mask → Inpaint Encode → KSampler
```

The key difference is that the model is told which area to change.

---

## How to think about denoise in inpainting

Just like img2img:

* **lower denoise** = smaller, more conservative change

* **higher denoise** = larger, more aggressive change

Typical interpretation:

* **0.15 to 0.30** = subtle correction

* **0.35 to 0.50** = moderate edit

* **0.55 to 0.75** = strong replacement

* **0.80 to 1.00** = major regeneration

If you are only fixing or replacing one object, a middle range is usually best.

---

## If your sampler uses direct denoise

Some workflows have a direct **denoise** field.

In that case, just use it normally.

Good starting point:

```
denoise = 0.45 to 0.60
```

That is usually a solid first inpainting test.

---

## If your sampler is KSampler Advanced

If you are using **KSampler (Advanced)** and do not see a denoise field, the same rule from img2img applies:

* **lower `start_at_step`** = more change

* **higher `start_at_step`** = less change

Use the same approximate conversion:

```
denoise ≈ 1 - (start_at_step / steps)
```

Or:

```
start_at_step ≈ steps × (1 - desired denoise)
```

---

## Quick denoise cheat sheet

### If total steps = 20

* `start_at_step = 0` → denoise `1.0`

* `start_at_step = 4` → denoise `0.8`

* `start_at_step = 8` → denoise `0.6`

* `start_at_step = 10` → denoise `0.5`

* `start_at_step = 14` → denoise `0.3`

* `start_at_step = 16` → denoise `0.2`

### If total steps = 6

* `start_at_step = 0` → denoise `1.0`

* `start_at_step = 1` → denoise `0.83`

* `start_at_step = 2` → denoise `0.67`

* `start_at_step = 3` → denoise `0.50`

* `start_at_step = 4` → denoise `0.33`

* `start_at_step = 5` → denoise `0.17`

---

## Suggested starting settings

### For a normal non-Lightning checkpoint

Start with:

```
Steps: 20
CFG: 5 to 7
Sampler: dpmpp_sde
Scheduler: karras
Denoise: 0.45 to 0.60
```

If using **KSampler Advanced**, a good medium test is:

```
Steps: 20
start_at_step: 8 to 10
CFG: 5 to 7
Sampler: dpmpp_sde
Scheduler: karras
add_noise: enable
```

### For a Lightning-style checkpoint

Start with:

```
Steps: 6
CFG: 1.5
Sampler: dpmpp_sde
Scheduler: karras
Denoise: 0.50 to 0.67
```

If using **KSampler Advanced**, that usually means:

```
Steps: 6
start_at_step: 2 to 3
CFG: 1.5
Sampler: dpmpp_sde
Scheduler: karras
add_noise: enable
```

---

## Easy starting presets

### Subtle inpaint edit

Use this when you want to gently fix a region.

* denoise: `0.20 to 0.35`

* or, with 20 steps: `start_at_step = 13 to 16`

### Medium inpaint edit

Use this when you want to clearly replace something, but preserve the overall scene.

* denoise: `0.45 to 0.60`

* or, with 20 steps: `start_at_step = 8 to 10`

### Strong inpaint edit

Use this when you want the masked area heavily reimagined.

* denoise: `0.70 to 0.90`

* or, with 20 steps: `start_at_step = 2 to 6`

---

## Prompting guidance for inpainting

The prompt should describe **what you want in the masked area**.

Good examples:

* “replace the masked area with a red leather jacket”

* “a realistic stone wall with ivy in the masked area”

* “remove the object and replace it with matching grass”

* “a clear blue sky with soft clouds”

It helps to describe the replacement as if it belongs naturally in the existing image.

---

## Best first tests

These are easy first inpainting experiments:

1. remove a small object from a table

2. replace part of the sky

3. change a shirt color

4. replace a section of a wall

5. remove clutter from a room photo

These are good because the target edit is simple and easy to judge.

---

## Simple mental model

Use this when choosing between workflows:

### Text-to-image

Make an image from scratch.

### Img2img

Change the whole image.

### Inpainting

Change only the masked area.

---

## Minimal workflow summary

### Full img2img

```
Load Image → VAE Encode → KSampler
```

### Inpainting

```
Load Image + Mask → Inpaint Encode → KSampler
```

### Core rule

```
White mask = change this
Black mask = keep this
```

### Strength rule

```
Lower denoise = preserve more
Higher denoise = change more
```

---

## Recommended first inpainting test

If you want one good first run, use:

### Normal checkpoint

* `steps = 20`

* `denoise = 0.5`

* `cfg = 6`

or with KSampler Advanced:

* `steps = 20`

* `start_at_step = 10`

* `cfg = 6`

Then mask a simple object and prompt something like:

```
replace the masked area with natural-looking grass, realistic, matching the surrounding image
```

or:

```
replace the masked area with a clean blue sky with soft clouds, realistic, seamless
```

---

## Shortest possible reminder

If you want the condensed version:

### Img2img

```
Load Image → VAE Encode → KSampler
```

### Inpainting

```
Load Image + Mask → Inpaint Encode → KSampler
```

### Meaning of the mask

```
White = change
Black = preserve
```

### Strength

```
Low denoise = subtle edit
High denoise = stronger edit
```

If you want, the next thing I can give you is a **very short “which workflow do I use?” cheat sheet** covering text-to-image, img2img, inpainting, and outpainting in one page.
