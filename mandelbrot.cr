require "option_parser"

# To make docker play nice
Signal::INT.trap { exit 1 }
Signal::TERM.trap { exit 1 }

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
        result << "*"
      else
        result << " "
      end
    end
    result << "\n"
  end
  result << "\e[0m"
  result[0, result.size - 1].join
end

def zoomer(left : Float64, right : Float64, top : Float64, bottom : Float64,
           max : Int32) String
  input = ' '
  left0, right0, top0, bottom0 = left, right, top, bottom
  while input != 'q'
    size            = `stty size`.split
    x, y            = size[1].to_f - 1, size[0].to_f - 3

    step_x = (right - left) / x
    step_y = (bottom - top) / y

    print render(left: left, right: right, top: top, bottom: bottom, step_x: step_x, step_y: step_y, max: max)
    puts "pan: h/j/k/l, zoom: i=in, o=out, r=reset, q=quit"
    print "mandelbrot -l #{left} -r #{right} -t #{top} -b #{bottom}] #{step_x} #{step_y}"

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
      left += step_x
      right -= step_x 
      top -= step_x
      bottom += step_x
    when 'o'
      left -= step_x
      right += step_x
      top += step_x
      bottom -= step_x
    when 'r'
      left = left0
      right = right0
      top = top0
      bottom = bottom0
    end
  end
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
