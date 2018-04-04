# Mandelbrot Set

```sh
# center
mandelbrot
```

## Fun Places to Zoom Out

```sh
mandelbrot -l -0.7487667169208654 -r -0.7487666890984621 -t 0.12364085859010267 -b 0.12364084306850771

mandelbrot -l -0.10702156711896195 -r -0.10702098035177825 -t -0.9129125599646061 -b -0.9129131344309852
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
