vcl 4.0;
sub vcl_recv {
  # normalize encoding
  if(req.http.Accept-Encoding) {
    if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2)$") {
      unset req.http.Accept-Encoding;
    } elsif (req.http.Accept-Encoding ~ "gzip") {
      set req.http.Accept-Encoding = "gzip";
    } elsif (req.http.Accept-Encoding ~ "deflate") {
      set req.http.Accept-Encoding = "gzip";
    } else {
      unset req.http.Accept-Encoding;
    }
  }

  # remove cookies to assets requests
  if (req.url ~ "^/assets/") {
   unset req.http.Cookie;
   return (hash);
  }
}

# Called when a response has come back from the back-end (on a cache miss)
# Variables:
# bereq  -> incoming request
# beresp -> backend response
sub vcl_backend_response {
  if (bereq.method == "GET" && bereq.url ~ "^/assets/") {
    set beresp.ttl = 1m;
    set beresp.http.Cache-Control = "public, max-age=86400";
    unset beresp.http.Set-Cookie;
  }
}
