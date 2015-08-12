module Login

	def self.invoke(actions, context)
		referer = context.referer
		[301, { 'Location' => referer }, ['Login Redirect']]
	end

end