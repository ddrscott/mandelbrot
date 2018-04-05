require 'opencl_ruby_ffi'
require 'narray_ffi'
require 'benchmark'

platform = OpenCL.platforms.first
device = platform.devices.first
context = OpenCL.create_context(device)
queue = context.create_command_queue(device, properties: OpenCL::CommandQueue::PROFILING_ENABLE)
source = File.read(File.join(File.expand_path(__dir__), 'kernel', 'mandel.cl'))
prog = context.create_program_with_source(source)
prog.build

num_points = 1000 * 1000
x_in = NArray.float(num_points).random(1.0)
y_in = NArray.float(num_points).random(1.0)

result_out = NArray.int(num_points)

iterations = OpenCL::Int8.new(500)
x_buff = context.create_buffer(x_in.size * x_in.element_size, flags: OpenCL::Mem::COPY_HOST_PTR, host_ptr: x_in)
y_buff = context.create_buffer(y_in.size * y_in.element_size, flags: OpenCL::Mem::COPY_HOST_PTR, host_ptr: y_in)
result_buff = context.create_buffer(result_out.size * result_out.element_size)

# event = prog.mandelbrot(queue, [num_points],
#                         x_buff, y_buff, iterations, result_buff, local_work_size: [128])
k = prog.create_kernel('mandelbrot')
k.set_arg(0, x_buff)
k.set_arg(1, y_buff)
k.set_arg(2, iterations)
k.set_arg(3, result_buff)

puts Benchmark.measure {
  event = queue.enqueue_ndrange_kernel(k, [65536], local_work_size: [128])
  queue.enqueue_read_buffer(result_buff, result_out, event_wait_list: [event])
  queue.finish
}

10.times do |i|
  puts(i => [x_in[i], y_in[i], result_out[i]])
end
puts 'Success!'

