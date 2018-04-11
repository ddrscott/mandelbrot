require "option_parser"

# To make docker play nice
Signal::INT.trap { exit 1 }
Signal::TERM.trap { exit 1 }

ANSI_MAP = %w(@ 0 # % X x o * + - . . .)
MIN_ZOOM = 2.0e-13

# Formula from https://www.mathworks.com/help/distcomp/examples/illustrating-three-approaches-to-gpu-computing-the-mandelbrot-set.html?s_tid=gn_loc_drop#d119e4796
def mandelbrot(real0, img0, max)
  real = real0
  img = img0
  count = 0
  while count < max && real * real + img * img <= 4.0
    count += 1
    old_r = real
    real = real * real - img * img + real0
    img = 2.0 * old_r * img + img0
  end
  return count
end

def render(left, right, top, bottom, step_x, step_y, max) String
  result = [] of String
  result << "\e[2J\e[0;0H"
  top.step(to: bottom, by: step_y) do |y|
    left.step(to: right, by: step_x) do |x|
      loops = mandelbrot(x, y, max)
      if loops == max
        result << " "
      elsif loops == 0
        result << ANSI_MAP[0]
      else
        c = loops.fdiv(max) * ANSI_MAP.size
        result << ANSI_MAP[c.to_i]
      end
    end
    result << "\n"
  end
  result << "\e[0m"
  result[0, result.size - 1].join
end

def zoomer(mid_x, mid_y, zoom, max : Int32) String
  print "\e[?47h"     # use alternate terminal screen output
  input = ' '

  mid_x0, mid_y0, zoom0, max0 = mid_x, mid_y, zoom, max
  while input != 'q'
    size            = `stty size`.split
    view_width, view_height            = size[1].to_f - 1, size[0].to_f - 2
    # scaled y coordinate of pixel (must be scaled to lie somewhere in the mandelbrot Y scale (-1, 1)
    scale_h = view_height * 0.5 / view_height * 2.0 * zoom
    scale_w =  view_width * 0.5 /  view_width * 3.5 * zoom

    top    = -scale_h - mid_y
    bottom =  scale_h - mid_y
    left   = -scale_w - mid_x
    right  =  scale_w - mid_x

    step_x = (right - left) / view_width
    step_y = (bottom - top) / view_height

    zoom = [MIN_ZOOM, zoom].max

    print render(left: left, right: right, top: top, bottom: bottom, step_x: step_x, step_y: step_y, max: max)
    print "\e[1;32m pan: w/a/s/d h/j/k/l, zoom: i=in, o=out, r=reset, iterations: =: more, -: less, quit: q\n"
    print "\e[1;36m -x #{mid_x} -y #{mid_y} -z #{zoom} --max #{max}\e[0m"

    inc = [step_x.abs, step_y.abs].max
    input = STDIN.raw &.read_char
    case input
    when 'd', 'l'
      mid_x -= step_x * 2
    when 's', 'j'
      mid_y -= step_y * 2
    when 'w', 'k'
      mid_y += step_y * 2
    when 'a', 'h'
      mid_x += step_x * 2
    when 'i'
      zoom *= 0.96
    when 'o'
      zoom *= 1.04
    when 'I'
      zoom *= 0.8
    when 'O'
      zoom *= 1.2
    when 'r'
      mid_x, mid_y, zoom, max = mid_x0, mid_y0, zoom0, max0
    when '='
      max += 1
    when '-'
      max -= 1
    end
  end
ensure
  print "\e[?47l"     # switch back to primary screen
end

# Defaults
x            = 0.75
y            = 0.0
zoom         = 1.0
max_iterations  = 100
fps             = -1.0
delay           = -1.0

OptionParser.parse! do |parser|
  parser.banner = "Usage: mandelbrot [arguments]"
  parser.on("-x X", "center point X") { |val| x = val.to_f }
  parser.on("-y Y", "center point Y") { |val| y = val.to_f }
  parser.on("-z ZOOM", "--zoom=ZOOM", "initial zoom") { |val| zoom = val.to_f }
  parser.on("--max MAX", "--max=MAX", "max iterations") { |val| max_iterations = val.to_i }
  parser.on("--fps=FPS", "max FPS") { |val| delay = 1.0 / val.to_f }
  parser.on("--help", "Show this help") do
    puts parser
    exit(0)
  end
end

zoomer(mid_x: x, mid_y: y, zoom: zoom, max: max_iterations)
# : mandelbrot -x 0.7495500935639509 -y -0.06371993917250125 -z 0.6866512314685467 --max 239
# mandelbrot -x 0.7494718949168628 -y -0.10770718066649793 -z 2.5642564948936334e-15 --max 100
# mandelbrot -x 0.37643238557024805 -y -0.6722880311475035 -z 1.8463281043800022e-13 --max 118  1.0
# mandelbrot -x 0.7288780059956085 -y -0.29203160173167625 -z 1.6e-13 --max 196
