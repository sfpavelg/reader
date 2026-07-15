# Tetris Dictionary

This folder stores derived data for the syllable tetris mode.

## Data model

- `blocks_v1.json`: unique 2-letter blocks and their weights.
- `words_v1.json`: words that are fully decomposable into 2-letter parts.
- `statistics.json`: build-time coverage and validation metrics.

## Build

Run:

```bash
python tooling/build_tetris_dictionary.py
```

The generator reads from:

- `assets/dictionary/level_2.json`
- `assets/dictionary/schulte_grid_words.json`

and writes outputs into this directory.
