vcl 4.0;
sub vcl_recv {
  # If header specifies "no-cache", don't serve from the cache.
  if (req.http.Pragma ~ "no-cache" || req.http.Cache-Control ~ "no-cache" || req.http.CacheIgnore ~ "true") {
    # https://www.varnish-cache.org/trac/wiki/VCLExampleHashAlwaysMiss
    # this is better than saying "pass" since it will also refresh the cache
    # with the result of this response.
    #
    # This allows us to warm the cache with Pragma: no-cache requests.
    set req.hash_always_miss = true;
  }
}
