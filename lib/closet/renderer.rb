module Wire
	# Renderer is a module for mapping mime to rendering templates
	# @author Bryan T. Meyers
	module Renderer

		# Setup a Renderer
		# @param [Class] klass the type of renderer to use
		# @param [Proc] block for configuring this renderer
		# @return [void]
		def renderer(klass, &block)
			$current_renderer = klass
			$current_editor   = nil
			Docile.dsl_eval(self, &block)
		end

		# Associate a MIME type to the current Renderer or Editor
		# @param [String] mime the MIME type
		# @return [void]
		def mime(mime)
			if $current_renderer
				$renderers[mime]              = $current_renderer
				$templates[$current_renderer] = $current_template
			end
			if $current_editor
				$editors[mime] = $current_editor
			end
		end

		# Setup a new template
		# @param [String] template the template for a renderer or editor
		# @return [void]
		def partial(template)
			$current_template = Tilt.new(template, 1, { ugly: true })
		end

		# Setup an Editor
		# @param [Class] editor the template for this Editor
		# @param [Proc] block for configuring this Editor
		# @return [void]
		def editor(editor, &block)
			$current_editor   = Tilt.new(editor, 1, { ugly: true })
			$current_renderer = nil
			Docile.dsl_eval(self, &block)
		end
	end
end