#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------


module TT::Plugins::UV_Toolkit
  
  ### MENU & TOOLBARS ### ------------------------------------------------------
  
  unless file_loaded?( __FILE__ )      
		@menu.add_item('Frontface Material to Backface') {
      self.mirror_selected_materials(true)
    }
		@menu.add_item('Backface Material to Frontface') {
      self.mirror_selected_materials(false)
    }
  end # UI
  file_loaded( __FILE__ )
  
  
  ### COMPATIBILITY ### --------------------------------------------------------

  if defined?(Sketchup::Set)
    Set = Sketchup::Set
  end

  ### GENERIC TOOLS ### --------------------------------------------------------
  
  
  def self.mirror_selected_materials(front_to_back=true)
    model = Sketchup.active_model
		tw = Sketchup.create_texture_writer
		
    if front_to_back
      operation_name = 'Frontface Material to Backface'
    else
      operation_name = 'Backface Material to Frontface'
    end
    
		TT::Model.start_operation( operation_name )
		
		definitions = Set.new
		entities = model.selection.to_a
    
    size = TT::Entities.count_unique_entity( entities )
    progress = TT::Progressbar.new( size, operation_name )
		
		until entities.empty?
      progress.next
			e = entities.shift
			if e.is_a?(Sketchup::Face)
				TT::Face.mirror_material( e, tw, front_to_back )
			elsif TT::Instance.is?( e )
        definition = TT::Instance.definition( e )
        unless definitions.include?( definition )
					entities += definition.entities.to_a
					definitions.insert( definition )
				end
			end
		end
		
		model.commit_operation
  end
  
  
  ### GENERAL METHODS ### ------------------------------------------------------
    
  
  def self.valid_quad_face_selection?
    sel = Sketchup.active_model.selection
    sel.length > 0 &&
    (sel.length > 10000 || sel.any? { |e| TT::Face.is_quad?( e ) })
  end

end # module
