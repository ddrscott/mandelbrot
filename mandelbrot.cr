require "option_parser"

# To make docker play nice
Signal::INT.trap { exit 1 }
Signal::TERM.trap { exit 1 }

ANSI_MAP = %w(@ 0 % * " o ' .)

# Formula from https://www.mathworks.com/help/distcomp/examples/illustrating-three-approaches-to-gpu-computing-the-mandelbrot-set.html?s_tid=gn_loc_drop#d119e4796
def mandelbrot(real0 : Float64, img0 : Float64, max : Int32) : Int32
  real = real0
  img = img0
  count = 0
  while count < max && real * real + img * img <= 4.0
    count += 1
    # Update: z = z*z + z0
    old_r = real
    real = real * real - img * img + real0
    img = 2.0 * old_r * img + img0
  end
  return count
end

def render(left : Float64, right : Float64, top : Float64, bottom : Float64,
           step_x : Float64, step_y : Float64, max : Int32) String
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

def zoomer(left : Float64, right : Float64, top : Float64, bottom : Float64, max : Int32) String
  print "\e[?47h"     # use alternate terminal screen output
  input = ' '
  left0, right0, top0, bottom0, max0 = left, right, top, bottom, max
  while input != 'q'
    size            = `stty size`.split
    x, y            = size[1].to_f - 1, size[0].to_f - 2

    step_x = (right - left) / x
    step_y = (bottom - top) / y

    print render(left: left, right: right, top: top, bottom: bottom, step_x: step_x, step_y: step_y, max: max)
    puts  "\e[1;32m[ pan: h/j/k/l, zoom: i=in, o=out, r=reset, q=quit, iterations: K: more, J: less ]"
    print "\e[1;36m: mandelbrot -l #{left} -r #{right} -t #{top} -b #{bottom} --max #{max}\e[0m"

    input = STDIN.raw &.read_char
    case input
    when 'l'
      left += step_x
      right += step_x
    when 'k'
      top -= step_y
      bottom -= step_y
    when 'j'
      top += step_y
      bottom += step_y
    when 'h'
      left -= step_x
      right -= step_x
    when 'i'
      inc = step_x.abs
      left += inc
      right -= inc
      top -= inc
      bottom += inc
    when 'o'
      dec = step_x.abs
      left -= dec
      right += dec
      top += dec
      bottom -= dec
    when 'r'
      left = left0
      right = right0
      top = top0
      bottom = bottom0
      max = max0
    when 'K'
      max += 10
    when 'J'
      max -= 10
    end
  end
ensure
  print "\e[?47l"     # switch back to primary screen
end

# Defaults
left            = -2.0
right           = 0.5
top             = 1.0
bottom          = -1.0
zoom            = 1.0
max_iterations  = 100
fps             = -1.0
delay           = -1.0

OptionParser.parse! do |parser|
  parser.banner = "Usage: mandelbrot [arguments]"
  parser.on("-l LEFT", "--left=LEFT", "initial left edge") { |val| left = val.to_f }
  parser.on("-r RIGHT", "--right=RIGHT", "initial right edge") { |val| right = val.to_f }
  parser.on("-t TOP", "--top=TOP", "initial top edge") { |val| top = val.to_f }
  parser.on("-b BOTTOM", "--bottom=BOTTOM", "initial bottom edge") { |val| bottom = val.to_f }
  parser.on("-z ZOOM", "--zoom=ZOOM", "initial zoom") { |val| zoom = val.to_f }
  parser.on("--max MAX", "--max=MAX", "max iterations") { |val| max_iterations = val.to_i }
  parser.on("--fps=FPS", "max FPS") { |val| delay = 1.0 / val.to_f }
  parser.on("--help", "Show this help") do
    puts parser
    exit(0)
  end
end

zoomer(left: left, right: right, top: top, bottom: bottom, max: max_iterations)
