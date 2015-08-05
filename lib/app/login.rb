
module Login

    def self.invoke( actions , context )
      referrer = context[:request].env['HTTP_REFERER']
      [301, {'Location' => referrer},['Login Redirect']]
    end

end