# nginx-docker

Docker image of nginx with ngx_pagespeed & ngx_brotli. Uses automatic install script from [ngxpagespeed.com/install](ngxpagespeed.com/install).

## Structure

Directory structure is a little bit different tahn standard nginx install via package manager.
Main ferectory is **/usr/local/nginx/**. In this directory you could find `logs/` and `conf/` directories.

## Arguments

* **user_uid** - UID number for nginx user
* **group_gid** - GID number for nginx group
* **port** - port number to be exposed