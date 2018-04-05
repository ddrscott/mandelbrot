/* Thanks:
 * - https://www.tinycranes.com/blog/2015/05/visualizing-the-mandelbrot-set/
 */
__kernel void mandel(__global double const * real0,
                     __global double const * img0,
                              int max,
                     __global int * result) {
  unsigned int i = get_global_id(0);

  double real = real0[i];
  double img = img0[i];
  int count = 0;
  double old_r = 0;
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
