# Mandelbrot Set

<img src="screenshot.png" alt="Screenshot of Mendelbrot Set" />

```sh
# center
crystal src/ansi.cr

# another place
crystal src/ansi.cr -l -0.7487667169208654 -r -0.7487666890984621 -t 0.12364085859010267 -b 0.12364084306850771

# yet another place, with more detail
crystal src/ansi.cr -l -0.10731654060226994 -r -0.106766205630802 -t -0.9124674709650323 -b -0.913017793635695 --max 179
```

## Usage

```
Usage: mandelbrot [arguments]
    -l LEFT, --left=LEFT             initial left edge
    -r RIGHT, --right=RIGHT          initial right edge
    -t TOP, --top=TOP                initial top edge
    -b BOTTOM, --bottom=BOTTOM       initial bottom edge
    -z ZOOM, --zoom=ZOOM             initial zoom
    --max MAX, --max=MAX             max iterations
    --fps=FPS                        max FPS
    --help                           Show this help
```
