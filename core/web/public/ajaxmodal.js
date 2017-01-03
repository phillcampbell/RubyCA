jQuery( document ).ready(function( $ ) {
  $.fn.infomodal = function(title) {
    if(title===undefined || title===null ){
      title= "Info"
    }
    /*
    $("body").append(
      $("<div/>", { id: "infomodal", class: "modal hide fade", role: "dialog", tabindex: "-1", "aria-labelledby" : "Info"}).append(
        $("<div/>", {class: "modal-header"}).html('<button class="close" data-dismiss="modal" type="button">x</button><h3>'+title+'</h3>'),
        $("<div/>", {class: "modal-body"}).append(this),
        $("<div/>", {class: "modal-footer"}).html('<button class="btn" data-dismiss="modal">Close</button>')
      )
    );
    *
/*
<!-- Button trigger modal -->
<button type="button" class="btn btn-primary btn-lg" data-toggle="modal" data-target="#myModal">
  Launch demo modal
</button>

<!-- Modal -->
<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
        <h4 class="modal-title" id="myModalLabel">Modal title</h4>
      </div>
      <div class="modal-body">
        ...
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
        <button type="button" class="btn btn-primary">Save changes</button>
      </div>
    </div>
  </div>
</div>
    
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
*/
    $("body").append(
      $("<div/>", { id: "infomodal", class: "modal fade bd-example-modal-lg", role: "dialog", tabindex: "-1", "aria-labelledby": "Info"}).append(
        $("<div/>", {class: "modal-dialog modal-lg", role: "document"}).append(
          $("<div/>", {class: "modal-content"}).append(
            // Header
            $("<div/>", {class: "modal-header"}).append(
              $("<button/>", {class: "close", "data-dismiss": "modal",  type: "button"}).html('<span aria-hidden="true">&times;</span>'),
              $("<h3/>").text(title)
            ),
            //
            $("<div/>", {class: "modal-body"}).append(this),
            $("<div/>", {class: "modal-footer"}).html('<button class="btn" data-dismiss="modal">Close</button>')                      
          )
        )
      )
    );
    
    $('#infomodal').on('hidden', function (){
      $('#infomodal').remove();
    });
    $('#infomodal').modal();
  };
  
  $('[data-get="modal"]').click( function(e) {
    e.preventDefault();
    
    var modal_title = null;
    if ($(this).is('[data-title]')) { 
      modal_title = $(this).attr('data-title')
    };
		$.ajax({    
      url: $(this).attr("href"), 
      success: function(data) {
        $('<pre/>').text(data).infomodal(modal_title);
      },    
      error: function(jqXHR, textStatus, errorThrown) { 
        $('<p/>').html("Woops. Error on get info.<br/><br/>"+ jqXHR.status + " " + errorThrown).infomodal("Error");
      }
    });
  });  
});