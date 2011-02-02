#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------


module TT::Plugins::UV_Toolkit
  
  ### MODULE VARIABLES ### -------------------------------------------------
  
  @clipboard = []
  
  
  ### PUBLIC ACCESSORS ### -------------------------------------------------
  
  def self.clipboard; @clipboard; end;
  
  
  ### MENU & TOOLBARS ### --------------------------------------------------
  
  unless file_loaded?( __FILE__ )      
    cmdCopy = UI::Command.new('Copy') {
      self.copy_uv
    }
    cmdCopy.set_validation_proc { self.can_copy_proc }
    cmdCopy.large_icon = 'Images/copy_24.png'
    cmdCopy.small_icon = 'Images/copy_16.png'
    cmdCopy.status_bar_text = 'Copy UV Co-ordinates of selected quad-faces.'
    cmdCopy.tooltip = 'Copy UV Co-ordinates'
    
    cmdPaste = UI::Command.new('Paste') {
      self.paste_uv
    }
    cmdPaste.set_validation_proc { self.can_paste_proc }
    cmdPaste.large_icon = 'Images/paste_24.png'
    cmdPaste.small_icon = 'Images/paste_16.png'
    cmdPaste.status_bar_text = 'Paste UV Co-ordinates onto selected quad-faces.'
    cmdPaste.tooltip = 'Paste UV Co-ordinates'
    
    cmdPaste_h = UI::Command.new('Paste - Flip Left/Right') {
      self.paste_uv( true )
    }
    cmdPaste_h.set_validation_proc { self.can_paste_proc }
    cmdPaste_h.large_icon = 'Images/paste_h_24.png'
    cmdPaste_h.small_icon = 'Images/paste_h_16.png'
    cmdPaste_h.status_bar_text = 'Paste UV Co-ordinates flipped horisontally onto selected quad-faces.'
    cmdPaste_h.tooltip = 'Paste UV Co-ordinates flipped horisontally'
    
    cmdPaste_v = UI::Command.new('Paste - Flip Top/Bottom') {
      self.paste_uv( false, true )
    }
    cmdPaste_v.set_validation_proc { self.can_paste_proc }
    cmdPaste_v.large_icon = 'Images/paste_v_24.png'
    cmdPaste_v.small_icon = 'Images/paste_v_16.png'
    cmdPaste_v.status_bar_text = 'Paste UV Co-ordinates flipped vertically onto selected quad-faces.'
    cmdPaste_v.tooltip = 'Paste UV Co-ordinates flipped vertically'
    
    cmdPaste_hv = UI::Command.new('Paste - Flip Both') {
      self.paste_uv( true, true )
    }
    cmdPaste_hv.set_validation_proc { self.can_paste_proc }
    cmdPaste_hv.large_icon = 'Images/paste_hv_24.png'
    cmdPaste_hv.small_icon = 'Images/paste_hv_16.png'
    cmdPaste_hv.status_bar_text = 'Paste UV Co-ordinates flipped horisontally and vertically onto selected quad-faces.'
    cmdPaste_hv.tooltip = 'Paste UV Co-ordinates flipped horisontally and vertically'
    
    # Menu
    #@menu.add_separator
    #menu_clipboard = @menu.add_submenu('UV Clipboard')
    #menu_clipboard.add_item( cmdCopy )
    #menu_clipboard.add_item( cmdPaste )
    #menu_clipboard.add_item( cmdPaste_h )
    #menu_clipboard.add_item( cmdPaste_v )
    #menu_clipboard.add_item( cmdPaste_hv )
    
    # Context Menu
    UI.add_context_menu_handler { |context_menu|
      if self.can_copy? || self.can_paste?
        m = context_menu.add_submenu( 'UV Co-ordinates' )
        m.add_item( cmdCopy )
        m.add_item( cmdPaste )
        m.add_item( cmdPaste_h )
        m.add_item( cmdPaste_v )
        m.add_item( cmdPaste_hv )
      end
    }
    
    # Toolbar
    @toolbar.add_item( cmdCopy )
    @toolbar.add_item( cmdPaste )
    @toolbar.add_item( cmdPaste_h )
    @toolbar.add_item( cmdPaste_v )
    @toolbar.add_item( cmdPaste_hv )
  end # UI
  file_loaded( __FILE__ )
  
  
  def self.can_paste?
    !@clipboard.empty? &&
    #@clipboard[:material].valid? &&
    self.valid_quad_face_selection?
  end
  
  
  def self.can_paste_proc
    if self.can_paste?
      MF_ENABLED
    else
      MF_DISABLED | MF_GRAYED
    end
  end
  
  
  def self.can_copy?
    sel = Sketchup.active_model.selection
    sel.length == 1 &&
    TT::Face.is_quad?( sel[0] ) &&
    sel[0].material &&
    sel[0].material.texture
  end
  
  
  def self.can_copy_proc
    #if self.can_copy?
    if self.valid_quad_face_selection?
      MF_ENABLED
    else
      MF_DISABLED | MF_GRAYED
    end
  end


  def self.copy_uv
    tw = Sketchup.create_texture_writer
    model = Sketchup.active_model
    
    @clipboard.clear
    model.selection.each { |e|
      next unless e.is_a?( Sketchup::Face )
      
      corners = TT::Face.corners( e )
      next unless corners.size == 4
      
      uv_set = {
        :front => {
          :material => e.material,
          :uv => []
        },
        :back => {
          :material => e.back_material,
          :uv => []
        }
      }
      
      uvh = e.get_UVHelper(true, true, tw)
      corners.each { |v|

        if e.material && e.material.texture
          raw_uvq = uvh.get_front_UVQ( v.position )
          uvq = TT::UVQ.normalize( raw_uvq )
          uv_set[:front][:uv] << uvq
        end

        if e.back_material && e.back_material.texture
          raw_uvq = uvh.get_back_UVQ( v.position )
          uvq = TT::UVQ.normalize( raw_uvq )
          uv_set[:back][:uv] << uvq
        end
        
      }
      
      @clipboard << uv_set
    }
    true
  end
  
  
  # Applies a random set of UV data for each quad-face in the selection.
  def self.paste_uv( flip_h = false, flip_v = false )
    self.cleanup_clipboard!
    return nil if @clipboard.empty?
    
    model = Sketchup.active_model
    sel = model.selection
    
    TT::SimpleTask.new( 'Paste UVs', sel, model ).run { |face|
      next unless TT::Face.is_quad?( face )
      
      corners = TT::Face.corners( face )
      next unless corners.size == 4
      
      index = rand( @clipboard.size )
      uv_set = @clipboard[ index ]
      
      uv_set.each { |side, uv_data|
        next if uv_data[:material] && uv_data[:material].deleted?
        
        if side == :front
          face.material = uv_data[:material]
        else
          face.back_material = uv_data[:material]
        end
        
        next if uv_data[:material].nil? || uv_data[:material].materialType == 0
        
        pts = []
        uv_data[:uv].each_with_index { |uvq, i|
          pt = corners[i]
          pts << pt
          pts << uvq
        }
        if flip_h
          pts = [
            pts[0], pts[3],
            pts[2], pts[1],
            pts[4], pts[7],
            pts[6], pts[5]
          ]
        end
        if flip_v
          pts = [
            pts[0], pts[7],
            pts[2], pts[5],
            pts[4], pts[3],
            pts[6], pts[1]
          ]
        end
        face.position_material( uv_data[:material], pts, side == :front )
      }
    } # SimpleTask 
    
    true
  end
  
  
  # Cleanup stale data.
  def self.cleanup_clipboard!
    @clipboard.reject! { |uv_data|
      front = uv_data[:front][:material]
      back  = uv_data[:back][:material]
      (front.nil? || front.deleted?) && (back.nil? || back.deleted?)
    }
  end

  
end # module