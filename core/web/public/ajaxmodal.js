jQuery( document ).ready(function( $ ) {
  $.fn.infomodal = function(title) {
    if(title===undefined || title===null ){
      title= "Info"
    }
    $("body").append(
      $("<div/>", { id: "infomodal", class: "modal hide fade", role: "dialog", tabindex: "-1", "aria-labelledby" : "Info"}).append(
        $("<div/>", {class: "modal-header"}).html('<button class="close" data-dismiss="modal" type="button">x</button><h3>'+title+'</h3>'),
        $("<div/>", {class: "modal-body"}).append(this),
        $("<div/>", {class: "modal-footer"}).html('<button class="btn" data-dismiss="modal">Close</button>')
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