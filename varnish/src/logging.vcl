vcl 4.0;
import std;

sub vcl_recv {
  if (req.hash_always_miss) {
    set req.http.X-Varnish-Cache = "bypass";
  }
}

sub vcl_hit {
  set req.http.X-Varnish-Cache = "hit";
}

sub vcl_miss {
  if (! req.http.X-Varnish-Cache) {
    set req.http.X-Varnish-Cache = "miss";
  }
}

sub vcl_pass {
  if (! req.http.X-Varnish-Cache) {
    set req.http.X-Varnish-Cache = "miss";
  }
}

# Called when about to send a response back to the client
sub vcl_deliver {
  if(req.http.x-forwarded-for) {
    std.log("remote_host:" + req.http.X-Forwarded-For);
  } else {
    std.log("remote_host:" + client.ip);
  }

  if(req.http.X-Remote-User-Agent) {
    std.log("user_agent:" + req.http.X-Remote-User-Agent);
  } else {
    std.log("user_agent:" + req.http.User-Agent);
  }

  std.log("cache_result:" + req.http.X-Varnish-Cache);
  set resp.http.X-Varnish-Cache = req.http.X-Varnish-Cache;
}
