/* Thanks:
 * - https://www.tinycranes.com/blog/2015/05/visualizing-the-mandelbrot-set/
 */
__kernel void mandel(__global float const * real0,
                     __global float const * img0,
                              int max,
                     __global int * result) {
  unsigned int i = get_global_id(0);

  float real = real0[i];
  float img = img0[i];
  float count = 0;
  float old_r = 0;
  while ((count < max) && (real * real + img * img <= 4.0))
  {
    count++;
    old_r = real;
    real = real * real - img * img + real0[i];
    img = 2.0 * old_r * img + img0[i];
  }
  result[i] = count;
}
// vim:ft=c
