#!/bin/sh
/usr/bin/java -cp "/usr/local/varnish_cachewarmer/*" com.groupon.m3.varnish.cachewarmer.CacheWarmer $@
