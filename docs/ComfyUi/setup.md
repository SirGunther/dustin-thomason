# Local Image Generation Setup

## ComfyUI + SDXL / RealVisXL on Windows with GTX 1080 Ti

Working configuration:

* Windows

* NVIDIA GTX 1080 Ti, 11 GB VRAM

* ComfyUI Desktop

* PyTorch 2.7.0

* CUDA 12.6

* SDXL

* RealVisXL 5.0

---

## 1. Install ComfyUI Desktop

Install **ComfyUI Desktop for Windows**.

ComfyUI is the application/runtime used to run local image-generation models. The actual image models are downloaded separately and loaded into ComfyUI.

---

## 2. Configure PyTorch for the GTX 1080 Ti

The GTX 1080 Ti is a Pascal GPU with compute capability **6.1**.

The current default ComfyUI Desktop installation may install a version of PyTorch/CUDA that no longer supports this GPU correctly.

ComfyUI has its own private Python virtual environment. For this installation, its Python executable is:

```
C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Installs\ComfyUI\ComfyUI\.venv\Scripts\python.exe
```

Close ComfyUI completely.

Open **Command Prompt** and run:

```
"C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Installs\ComfyUI\ComfyUI\.venv\Scripts\python.exe" -m pip install --force-reinstall torch==2.7.0 torchvision==0.22.0 torchaudio==2.7.0 --index-url https://download.pytorch.org/whl/cu126
```

This installs the known-working combination:

* `torch 2.7.0`

* `torchvision 0.22.0`

* `torchaudio 2.7.0`

* CUDA `12.6`

All three Torch packages should use matching versions and the same CUDA build.

---

## 3. Verify GPU Support

Before reopening ComfyUI, run:

```
"C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Installs\ComfyUI\ComfyUI\.venv\Scripts\python.exe" -c "import torch, torchvision, torchaudio; print('torch:',torch.__version__); print('cuda:',torch.version.cuda); print('GPU:',torch.cuda.get_device_name(0)); print('CC:',torch.cuda.get_device_capability(0)); print('CUDA works:',torch.cuda.is_available())"
```

Expected output:

```
torch: 2.7.0+cu126
cuda: 12.6
GPU: NVIDIA GeForce GTX 1080 Ti
CC: (6, 1)
CUDA works: True
```

If ComfyUI warns that CUDA 13.0 or newer is required for optimized CUDA operations, that warning can be ignored on the GTX 1080 Ti.

---

## 4. Load the SDXL Workflow

Open ComfyUI Desktop.

Open the workflow/template browser and search for:

```
sdxl
```

Select:

**SDXL Simple**

This workflow uses both:

* SDXL Base

* SDXL Refiner

---

## 5. Download the SDXL Models

When the workflow opens, ComfyUI will report that the required models are missing.

Download:

```
sd_xl_base_1.0.safetensors
sd_xl_refiner_1.0.safetensors
```

Together they are roughly 12 GB.

ComfyUI Desktop shows active downloads in the **downloads menu at the top of the interface**.

Wait for both downloads to finish, then refresh ComfyUI.

The shared checkpoint directory for this installation is:

```
C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Shared\models\checkpoints
```

---

## 6. Generate the First Image

In the SDXL workflow, enter a description into the positive prompt.

Example:

```
a cinematic photo of a golden retriever running through autumn leaves, warm sunlight, highly detailed
```

A basic negative prompt can be:

```
blurry, low quality, distorted, extra limbs
```

For an initial GTX 1080 Ti test, use:

```
Width: 768
Height: 768
```

Click **Run**, or press:

```
Ctrl + Enter
```

If the image generates successfully, the local image-generation environment is working.

---

## 7. Getting Better Models

Stock SDXL is primarily useful as a baseline.

For better image quality and different capabilities, download community-trained checkpoints.

The two main sources are:

* **Civitai** — especially useful for community checkpoints, example images, LoRAs, recommended settings, and model comparisons.

* **Hugging Face** — especially useful for official releases, research models, and model repositories.

For the current ComfyUI setup, the simplest models to add are **SDXL-compatible checkpoints in `.safetensors` format**.

When choosing one, check for information similar to:

```
Type: Checkpoint
Base Model: SDXL 1.0
Format: SafeTensor
```

---

## 8. Install RealVisXL 5.0

Current selected model:

**RealVisXL 5.0**

Source:

<https://civitai.com/models/139562/realvisxl-v50?modelVersionId=798204>

Download the `.safetensors` checkpoint.

Place it in:

```
C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Shared\models\checkpoints
```

Refresh or restart ComfyUI.

In the **Load Checkpoint** node, select the RealVisXL checkpoint from the dropdown.

RealVisXL is based on SDXL, so it can replace the stock SDXL Base checkpoint in an SDXL-compatible workflow.

The stock SDXL Refiner is generally unnecessary with a modern fine-tuned checkpoint such as RealVisXL unless the model's documentation specifically recommends using it.

---

## 9. Important ComfyUI Model Folders

Main checkpoints:

```
C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Shared\models\checkpoints
```

LoRAs:

```
C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Shared\models\loras
```

VAEs:

```
C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Shared\models\vae
```

ControlNet models:

```
C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Shared\models\controlnet
```

The common parent folder is:

```
C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Shared\models
```

---

# Python and Command-Line Tools

## 10. Python

A separate system-wide Python installation was **not required** for this setup.

ComfyUI Desktop provides its own Python virtual environment.

For this installation:

```
C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Installs\ComfyUI\ComfyUI\.venv\Scripts\python.exe
```

When modifying or testing ComfyUI's Python environment, use this executable rather than a generic system `python` command.

---

## 11. pip

Python packages were installed using **pip**, invoked through ComfyUI's own Python environment.

The general pattern is:

```
"C:\path\to\ComfyUI\.venv\Scripts\python.exe" -m pip <command>
```

This ensures that package changes are applied to ComfyUI rather than another Python installation on the machine.

---

## 12. Required Python Packages

The packages manually installed/reinstalled for GTX 1080 Ti compatibility were:

```
torch==2.7.0
torchvision==0.22.0
torchaudio==2.7.0
```

They were installed from the PyTorch CUDA 12.6 package repository:

```
https://download.pytorch.org/whl/cu126
```

These packages need to remain on compatible versions with matching CUDA builds.

---

## 13. Command Prompt

The command-line work was performed using the standard Windows **Command Prompt (`cmd.exe`)**.

No separate command-line shell was required.

---

## 14. Tools That Did Not Need Separate Installation

For this setup, it was not necessary to manually install:

* System-wide Python

* CUDA Toolkit

* cuDNN

* Git

* Conda

* Miniconda

* virtualenv

* a separate global copy of pip

ComfyUI Desktop provides the core Python environment itself.

The main manual correction was replacing its incompatible Torch stack with the GTX 1080 Ti-compatible versions.

---

# GTX 1080 Ti Troubleshooting

## 15. `no kernel image is available`

An incompatible modern PyTorch build produced:

```
CUDA error: no kernel image is available for execution on the device
```

This occurred because the installed PyTorch/CUDA build did not contain kernels compatible with the GTX 1080 Ti's compute capability 6.1.

The working solution was:

```
PyTorch 2.7.0
CUDA 12.6
```

---

## 16. TorchAudio CUDA Mismatch

After changing PyTorch, TorchAudio also has to use the same CUDA build.

A mismatch can produce an error similar to:

```
PyTorch has CUDA version 12.6 whereas TorchAudio has CUDA version 13.0
```

For that reason, reinstall all three packages together:

```
"C:\Users\dktho\AppData\Local\Comfy-Desktop\ComfyUI-Installs\ComfyUI\ComfyUI\.venv\Scripts\python.exe" -m pip install --force-reinstall torch==2.7.0 torchvision==0.22.0 torchaudio==2.7.0 --index-url https://download.pytorch.org/whl/cu126
```

---

## 17. Recovery Procedure

If a future ComfyUI update breaks GPU compatibility:

1. Close ComfyUI.

2. Open Command Prompt.

3. Reinstall the known-good Torch stack using the command above.

4. Run the GPU verification command.

5. Confirm:

```
torch: 2.7.0+cu126
cuda: 12.6
GPU: NVIDIA GeForce GTX 1080 Ti
CC: (6, 1)
CUDA works: True
```

6. Reopen ComfyUI and test generation.

---

# Current Working Configuration

```
GPU: NVIDIA GeForce GTX 1080 Ti
VRAM: 11 GB
Compute Capability: 6.1

ComfyUI: Desktop
Python: ComfyUI private virtual environment

PyTorch: 2.7.0+cu126
TorchVision: 0.22.0
TorchAudio: 2.7.0
CUDA Runtime: 12.6

Base Architecture: SDXL
Stock Models:
- SDXL Base 1.0
- SDXL Refiner 1.0

Current Fine-Tuned Model:
- RealVisXL 5.0
```

That is the version I would actually save. It contains the **successful path only**, including the Python fix that turned out to be essential, without documenting all the false starts.
