#include <Rcpp.h>
using namespace Rcpp;

IntegerVector decimal_to_fraction_cont(const double x, const long max_denom) {
  long      n0 = 0;
  long      n1 = 1;
  long long n2 = floor(x);
  long      d0 = 0;
  long      d1 = 0;
  long long d2 = 1;
  long long f  = n2;
  double    z  = x - n2;

  while (d2 <= max_denom) {
    z  = 1 / z;
    f  = (long long) floor(z);
    z  = z - (double) f;
    n0 = n1;
    n1 = (long) n2;
    n2 = f * (long long) n1 + (long long) n0;
    d0 = d1;
    d1 = (long) d2;
    d2 = f * (long long) d1 + (long long) d0;
    if (fabs(x - (double) n1 / (double) d1) < DBL_EPSILON) {break;}
    if (f == 0) {break;}
  }

  if (n1 == LONG_MIN) {
    n1 = (long) ceil(x);
    d1 = 1;
  } else if (d1 == LONG_MIN) {
    n1 = (long) floor(x);
    d1 = 1;
  }

  return IntegerVector::create(n1, d1);
}

IntegerVector decimal_to_fraction_base_10(const double x, const long max_denom)
{
  long n = 0;
  long d;

  for (long i = 1; i <= max_denom; i *= 10) {
    d = i;
    n = (long) R::fround(x * d, 0);
    if (fabs(x - (double) n / (double) d) <= DBL_EPSILON) {break;}
  }

  return IntegerVector::create(n, d);
}

// [[Rcpp::export]]
IntegerMatrix decimal_to_fraction(
    const NumericVector x, const bool base_10, const long max_denom
) {
  IntegerMatrix result(2, x.size());

  if (base_10) {
    for (int i = 0; i < x.size(); i++) {
      result(_, i) = decimal_to_fraction_base_10(x[i], max_denom);
    }
  } else {
    for (int i = 0; i < x.size(); i++) {
      result(_, i) = decimal_to_fraction_cont(x[i], max_denom);
    }
  }

  return result;
}