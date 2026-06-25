# QWEN Workflow Notes

QWEN can produce many visual variants from one broad prompt, but for production layers it tends to:

- draw a full character when given `body.png`;
- add scenes/backgrounds if the prompt is not strict;
- change style between attempts;
- produce wide 1024x571 frames instead of square 1024x1024 unless square output is repeated clearly;
- create useful effect assets (star/comet) better than precise character layers.

Working strategy:

1. Use QWEN for **effects** and rough variants:
   - star
   - comet
   - sparkle
   - maybe emotion/mouth experiments

2. For precise layers, attach as few references as possible:
   - for wink eyes: attach only `eyes_open.png`;
   - for mouth: attach `body.png` only if needed, but strongly forbid full character output;
   - for body variants: ask for one exact stage at a time.

3. Prompt pattern:
   - “one image only”
   - “one asset only”
   - “no collage”
   - “no full character”
   - “pure white background”
   - “1024x1024 square”
   - “layer must be interchangeable in Flutter”

4. Do not keep failed generations in project assets. Only save useful outputs and prompts that produced them.
