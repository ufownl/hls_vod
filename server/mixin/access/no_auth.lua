local method = ngx.req.get_method()
if method == "OPTIONS" then
  ngx.exit(ngx.HTTP_NO_CONTENT)
end
