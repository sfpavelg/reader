# QWEN prompt: extract mouth from face reference

I will attach one reference image:

`face_smile_reference.png` — orange character face with eyes and a small cute smile.

Task:
Create a separate mouth asset by extracting/recreating only the smile from the reference image.

Asset name: `stage_06_adult/mouth_smile.png`

What to copy:
- Copy the exact smile style from `face_smile_reference.png`.
- Same small friendly curved mouth.
- Same cute child-friendly expression.
- Same thin dark outline and tiny warm orange/red inner detail.
- The mouth must look like it belongs to the same orange mascot.

Strict requirements:
- Mouth only.
- No eyes.
- No orange face.
- No orange body.
- No head.
- No full character.
- No cheeks.
- No background objects.
- No text.
- No labels.
- No multiple options.
- Pure white background only.
- Square image, 1024x1024.

Important:
Do not invent a new mouth design. Recreate only the tiny simple smile from the reference as closely as possible, just cleaner and larger.

Shape correction:
- The mouth should be a small simple U-shaped smile.
- Thin dark brown curved line.
- Slight orange/red fill only inside the smile if needed.
- No round blobs at the ends.
- No cheek circles.
- No side knots.
- No extra lower line below the smile.
- No thick banana shape.
- No large open mouth.
- No 3D inflated tube.

Scale and composition:
- Put one single mouth in the center.
- The mouth should occupy about 12-18% of image width.
- Leave large clean white space around it.
- The mouth should be small and light, not thick.

Negative prompt:
No thick lips. No realistic lips. No sausage shape. No banana shape. No inflated 3D tube. No large mouth. No side blobs. No cheek circles. No extra lower stroke. No teeth. No tongue. No face. No eyes. No body. No full character. No scene. No collage.

Output:
One clean centered smile layer on white background, ready to be used as `mouth_smile.png` in Flutter.

Result:
- Saved as `assets/characters/kolobok/stage_06_adult/mouth_smile.png`.
- Size: 1024x708.
- White background.
- Good enough as the working smile layer. The side tips can be manually simplified later if needed.
