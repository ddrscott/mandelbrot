# rubocop:disable all
require 'benchmark'
require 'pry'
require 'pry-state'
require_relative './write_png.rb'

WORK_GROUP_SIZE = 65_536

cols = 1920
rows = 1440
max  =  512

      top    = 1.0
left = -2.0;       right = 0.5
      bottom = -1.0

step_w = (right - left) / cols
step_h = (bottom - top) / rows
p [step_w, step_h]

require 'opencl_ruby_ffi'
require 'narray_ffi'
platform = OpenCL.platforms.first
device = platform.devices.last
context = OpenCL.create_context(device)
queue = context.create_command_queue(device, properties: OpenCL::CommandQueue::PROFILING_ENABLE)
source = File.read(File.join(File.expand_path(__dir__), '..', 'kernel', 'mandel.cl'))
prog = context.create_program_with_source(source)
prog.build

num_points = cols * rows
x_in = NArray.float(num_points)
y_in = NArray.float(num_points)
iterations = OpenCL::Int8.new(max)
result_out = NArray.int(num_points)

# initalize points
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

x_buff = context.create_buffer(x_in.size * x_in.element_size, flags: OpenCL::Mem::COPY_HOST_PTR, host_ptr: x_in)
y_buff = context.create_buffer(y_in.size * y_in.element_size, flags: OpenCL::Mem::COPY_HOST_PTR, host_ptr: y_in)
result_buff = context.create_buffer(result_out.size * result_out.element_size)
k = prog.create_kernel('mandel')
k.set_arg(0, x_buff)
k.set_arg(1, y_buff)
k.set_arg(2, iterations)
k.set_arg(3, result_buff)

puts "OpenCL Time: " + (Benchmark.measure {
  event = queue.enqueue_ndrange_kernel(k, [num_points])
  # Using local_work_size doesn't make a difference.
  # event = queue.enqueue_ndrange_kernel(k, [num_points], local_work_size: [128])
  queue.enqueue_read_buffer(result_buff, result_out, event_wait_list: [event], blocking_read: true)
  queue.finish
}).to_s

WritePNG.write_png(cols:cols, rows:rows, max: max, values: result_out, dst: 'images/opencl.png')
