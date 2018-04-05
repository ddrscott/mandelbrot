# rubocop:disable all
require 'benchmark'
require_relative './write_png.rb'

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
  count
end

def solve_values(xs:, ys:, max:, dst:)
  puts Benchmark.measure {
    xs.each_with_index do |x, i|
      dst[i] = mandelbrot(x, ys[i], max)
    end
  }
end

cols = 250
rows = 200
max  = 200

      top    = 1.0
left = -2.0;       right = 0.5
      bottom = -1.0

step_w = (right - left) / cols
step_h = (bottom - top) / rows
p [step_w, step_h]
x_in = []
y_in = []

y = top
rows.times do |r|
  x = left
  cols.times do |c|
    offset =  r * cols + c
    x_in[offset] = x
    y_in[offset] = y
    x += step_w
  end
  y += step_h
end

ruby_result = []
solve_values(xs: x_in, ys: y_in, max: max, dst: ruby_result)
WritePNG.write_png(cols: cols, rows: rows, max: max, values: ruby_result, dst: 'images/ruby.png')
