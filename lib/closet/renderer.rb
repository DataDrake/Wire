module Wire
  module Renderer

    def renderer( klass , &block)
      $current_renderer = klass
      $current_editor = nil
      Docile.dsl_eval( self , &block )
    end

    def mime( mime )
      if $current_renderer
        @config[:renderers][mime] = $current_renderer
        @config[:templates][$current_renderer] = $current_template
      end
      if $current_editor
        @config[:editors][mime] = $current_editor
      end
    end

    def partial( template )
      $current_template = Tilt.new( template , 1 , {ugly:true})
    end

    def editor( editor , &block)
      $current_editor = Tilt.new( editor , 1 , {ugly:true})
      $current_renderer = nil
      Docile.dsl_eval( self , &block )
    end

  end

end