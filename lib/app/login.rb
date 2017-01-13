# Login is a Wire::App for forcing user logins
# @author Bryan T. Meyers
module Login

	# Proxy method used when routing
	# @param [Array] actions the allowed actions for this URI
	# @param [Hash] context the context for this request
	# @return [Response] a redirect message returning to the previous page
	def self.invoke(actions, context)
		[307, { 'Location': context.referer.join('/') }, ['Login Redirect']]
	end

end