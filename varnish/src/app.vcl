vcl 4.0;




backend default {
  .between_bytes_timeout = 60s;
  .first_byte_timeout = 60s;
  .host = "xxxxxxxx-xxxx-xxxxx-xxxx-xxx.xxxx";
  .port = "80";
  .connect_timeout = 3.5s;

}




sub vcl_recv {
  if (req.method == "PURGE") {
    return (purge);
  }


  if (req.method ~ "PUT") {
    return (pass);
  }


  if (req.method ~ "POST") {
    return (pass);
  }


  # don't cache anything without a client_id
  if (req.url !~ "client_id=[^&]+"){
    return (pass);
  }

}

sub vcl_hash {
  # strip out client_id from hash key logic (they are just noise and wreck caching)
  hash_data(regsuball(regsuball(req.url,"&?(client_id)=[^&]+",""), "(\?)&|\?\Z", "\1"));
return (lookup);

}

sub vcl_hit {
  
}

sub vcl_miss {
  
}

sub vcl_pass {
  
}

sub vcl_pipe {
  
}

sub vcl_backend_fetch {
  
}

sub vcl_backend_response {

  if (bereq.url ~ "^/merchantservice/") {
    set beresp.ttl = 15m;
  }





  if (beresp.status != 200) {
    set beresp.ttl = 0s;
    return (deliver);
  }


  
}

sub vcl_backend_error {

  
}
