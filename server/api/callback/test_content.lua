ngx.req.read_body()
ngx.log(ngx.ERR, ngx.var.callback, ": ", ngx.req.get_body_data())
