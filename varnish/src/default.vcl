vcl 4.0;

include "/etc/varnish/conf.d/cache_reload.vcl";
include "/etc/varnish/conf.d/app.vcl";
include "/etc/varnish/conf.d/assets.vcl";
include "/etc/varnish/conf.d/logging.vcl";

# http://www.slideshare.net/90kts/caching-with-varnish-9864681
# vcl_recv -> vcl_hash -> vcl_miss -> vcl_backend_response -> vcl_deliver
#          -> vcl_hash -> vcl_hit  ->                         vcl_deliver

# return(pass) -> don't cache, go straight to the back-end
# return(hash) -> try and lookup the request in the cache


sub vcl_recv {
  if (req.url == "/heartbeat.txt" || req.url == "/grpn/healthcheck" ) {
    return (synth(200, "OK"));
  }

  ### clean out requests sent via curls -X mode and LWP
  if (req.url ~ "^http://") {
    set req.url = regsub(req.url, "http://[^/]*", "");
  }

  ### host./foo and host/foo are the same url
  ### host:80/foo and host/foo are the same url
  set req.http.Host = regsub(req.http.Host, "www\.", "");
  set req.http.Host = regsub(req.http.Host, "\.?(:[0-9]*)?$", "");

  ### remove double // in urls,
  ### /foo and /foo/ are the same url
  set req.url = regsuball( req.url, "//", "/"      );
  set req.url = regsub( req.url, "/([?])?$", "\1"  );
}

# Called when a response has come back from the back-end (on a cache miss)
# Variables:
# req -> incoming request
# beresp -> backend response
sub vcl_backend_response {
  # keep objects in cache after expiration
  set beresp.grace = 2h;

  if (beresp.http.X-Run-ESI) {
    set beresp.do_esi = true;
    # Enable this to strip this header
    # unset beresp.http.X-Run-ESI;
  }
}
