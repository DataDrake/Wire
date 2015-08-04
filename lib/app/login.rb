get('/login') do
  updateSession( request , session )
  referrer = request.env['HTTP_REFERER']
  redirect referrer
end