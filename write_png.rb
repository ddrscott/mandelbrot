require 'chunky_png'

module WritePNG
  module_function

  def write_png(cols:, rows:, max:, values:, dst:)
    puts Benchmark.measure {
      # require 'oily_png'
      png = ChunkyPNG::Image.new(cols, rows, ChunkyPNG::Color::BLACK)
      rows.times do |r|
        cols.times do |c|
          offset = r * cols + c
          v = (values[offset].fdiv(max) * 255).to_i
          png[c, r] = ChunkyPNG::Color.rgba(v, v, v, 255)
        end
      end
      png.save(dst)
      `open #{dst}`
    }
  end
end
