# QWEN prompt: stage_06_adult/eyes_wink.png

I will attach two reference images:

1. `body.png` — adult orange Kolobok body, no face, white background.
2. `eyes_open.png` — the approved open eyes layer, white background.

Create the next matching layer:

Asset name: `stage_06_adult/eyes_wink.png`

Task:
Create only the eyes layer for the same adult Kolobok character. It must match the attached `eyes_open.png` in style, size, lighting, spacing, and position.

Expression:
- One eye is winking: happy closed curved eye.
- The other eye stays open and glossy brown.
- The expression should be friendly, playful, and safe for children age 6-7.

Strict requirements:
- Eyes only.
- No orange body.
- No face shape.
- No mouth.
- No eyebrows.
- No text.
- No labels.
- No book.
- No background objects.
- Use pure white background only.
- Do not use black, gray, gradient, or transparent-looking checkerboard background.
- Do not add shadows under the eyes.
- Do not draw any orange shape behind the eyes.
- Keep the same 3D cartoon style as the attached references.
- Keep the same lighting direction as `body.png` and `eyes_open.png`.
- Keep the eye pair centered.
- Keep the same approximate scale and horizontal placement as `eyes_open.png`.
- Square image, 1024x1024.

Compatibility requirement:
The generated `eyes_wink.png` must be interchangeable with `eyes_open.png` in Flutter. If I overlay both files at the same size and position over `body.png`, the eyes should line up naturally.

Composition guide:
- The full eye pair should occupy about the same width as in `eyes_open.png`.
- Leave clean white space around the eyes for easy background removal.
- The closed/winking eye should not become too small; it should read clearly at mobile size.

Negative prompt:
Do not generate a full character. Do not generate an orange blob. Do not generate a collage. Do not add captions. Do not add a black background. Do not change the style of the eyes.

Result:
- Saved as `assets/characters/kolobok/stage_06_adult/eyes_wink.png`.
- Size: 1024x1024.
- White background. Good enough for the current workflow; background will be removed later.
