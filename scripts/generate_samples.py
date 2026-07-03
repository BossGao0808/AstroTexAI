#!/usr/bin/env python3
"""Batch generate samples for Krea 2 Turbo and Chroma1-HD via ComfyUI API."""

import json
import time
import urllib.request
import urllib.error
import sys
import os
import shutil

COMFYUI_URL = "http://127.0.0.1:8188"
PROJECT_ROOT = "/Users/gaotianyu/Documents/Astro_TEX_AI"
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "outputs", "AITex", "2026-07-03")

KREA2_PROMPTS = [
    "A serene Japanese garden with cherry blossoms falling, koi pond, watercolor illustration style, soft pastel colors",
    "Cyberpunk street market at night, neon signs, rain-soaked pavement, holographic advertisements, digital painting",
    "A majestic phoenix rising from molten lava, fiery feathers, dramatic sky, fantasy concept art, highly detailed",
    "Minimalist flat design illustration of a mountain sunrise, geometric shapes, warm orange and teal palette",
    "Surreal floating islands with cascading waterfalls into the void, dreamlike atmosphere, oil painting style",
    "A vintage 1950s travel poster for the moon, retro illustration, bold colors, art deco typography",
    "Abstract geometric composition inspired by Bauhaus, primary colors, clean lines, modernist design poster",
    "A cozy bookstore cafe on a rainy evening, warm golden light, steam rising from coffee, storybook illustration",
    "A cosmic whale swimming through a galaxy of stars and nebulae, ethereal glow, digital art masterpiece",
    "Steampunk airship sailing above Victorian London, brass and copper gears, detailed concept art, golden hour",
]

CHROMA_PROMPTS = [
    "Portrait of a young woman with freckles and short red hair, natural window light, shot on 85mm lens, photorealistic",
    "Dramatic mountain landscape at golden hour, layers of misty peaks, a lone hiker on a ridge, cinematic wide shot",
    "A rustic Italian trattoria interior, checkered tablecloth, wine bottles, warm candlelight, 35mm film photography",
    "Tokyo Shibuya crossing at night in the rain, neon reflections, candid street photography, bokeh lights",
    "Close-up portrait of an elderly fisherman with weathered hands and deep wrinkles, dramatic side lighting, black and white",
    "Abandoned factory interior, shafts of light streaming through broken windows, dust particles, atmospheric",
    "A Michelin-star chef plating a delicate dessert, tweezers, micro herbs, food photography, shallow depth of field",
    "Aurora borealis dancing over a frozen lake with a lone cabin, starry sky, long exposure photography",
    "A vintage Porsche 911 parked on a desert highway at sunset, lens flare, Kodak film aesthetic",
    "Macro shot of a dewdrop on a spider web at dawn, golden bokeh background, extreme detail, nature photography",
]


def load_workflow(path):
    with open(path, "r") as f:
        return json.load(f)


def submit_prompt(workflow, prompt_text, seed):
    wf = json.loads(json.dumps(workflow))  # deep copy
    for node_id, node in wf.items():
        if node["class_type"] == "CLIPTextEncode":
            if "text" in node["inputs"] and node["inputs"]["text"] == "PROMPT_PLACEHOLDER":
                node["inputs"]["text"] = prompt_text
        if node["class_type"] == "KSampler":
            node["inputs"]["seed"] = seed

    data = json.dumps({"prompt": wf}).encode("utf-8")
    req = urllib.request.Request(
        f"{COMFYUI_URL}/prompt",
        data=data,
        headers={"Content-Type": "application/json"},
    )
    resp = urllib.request.urlopen(req)
    result = json.loads(resp.read())
    return result.get("prompt_id"), result


def wait_for_completion(prompt_id, timeout=600):
    start = time.time()
    while time.time() - start < timeout:
        try:
            req = urllib.request.Request(f"{COMFYUI_URL}/history/{prompt_id}")
            resp = urllib.request.urlopen(req)
            history = json.loads(resp.read())
            entry = history.get(prompt_id, {})
            status = entry.get("status", {}).get("status_str", "")
            if status == "success":
                return entry
            elif status == "error":
                print(f"  ERROR: {entry.get('status', {})}")
                return entry
        except Exception:
            pass
        time.sleep(3)
    print(f"  TIMEOUT after {timeout}s")
    return None


def get_output_images(history_entry):
    images = []
    outputs = history_entry.get("outputs", {})
    for node_id, node_output in outputs.items():
        for img in node_output.get("images", []):
            images.append(img)
    return images


def download_image(filename, subfolder, output_path):
    url = f"{COMFYUI_URL}/view?filename={filename}&subfolder={subfolder}&type=output"
    req = urllib.request.Request(url)
    resp = urllib.request.urlopen(req)
    with open(output_path, "wb") as f:
        f.write(resp.read())


def run_batch(workflow_path, prompts, model_name, filename_prefix, seeds):
    print(f"\n{'='*60}")
    print(f"  Generating {len(prompts)} samples with {model_name}")
    print(f"{'='*60}")

    workflow = load_workflow(workflow_path)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for i, prompt in enumerate(prompts):
        seed = seeds[i]
        print(f"\n[{i+1}/{len(prompts)}] seed={seed}")
        print(f"  Prompt: {prompt[:80]}...")

        prompt_id, result = submit_prompt(workflow, prompt, seed)
        if not prompt_id:
            print(f"  FAILED to submit: {result}")
            continue

        print(f"  Submitted: {prompt_id}")
        entry = wait_for_completion(prompt_id, timeout=300)
        if not entry:
            print(f"  FAILED: timeout or error")
            continue

        images = get_output_images(entry)
        if not images:
            print(f"  FAILED: no output images")
            continue

        for img in images:
            filename = img["filename"]
            subfolder = img.get("subfolder", "")
            out_name = f"{filename_prefix}_{i+1:02d}.png"
            out_path = os.path.join(OUTPUT_DIR, out_name)
            download_image(filename, subfolder, out_path)
            print(f"  Saved: {out_path}")

    print(f"\n{model_name} batch complete!")


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    krea2_seeds = [42, 137, 256, 512, 7331, 8888, 12345, 67890, 99999, 314159]
    chroma_seeds = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]

    # Run Krea 2 Turbo
    run_batch(
        workflow_path=os.path.join(PROJECT_ROOT, "workflows/krea2/krea2_turbo_t2i.json"),
        prompts=KREA2_PROMPTS,
        model_name="Krea 2 Turbo",
        filename_prefix="krea2_turbo",
        seeds=krea2_seeds,
    )

    # Run Chroma1-HD
    run_batch(
        workflow_path=os.path.join(PROJECT_ROOT, "workflows/chroma/chroma1_hd_t2i.json"),
        prompts=CHROMA_PROMPTS,
        model_name="Chroma1-HD",
        filename_prefix="chroma1_hd",
        seeds=chroma_seeds,
    )

    print(f"\n{'='*60}")
    print("  ALL DONE! Files in:")
    print(f"  {OUTPUT_DIR}")
    print(f"{'='*60}")
