jQuery( document ).ready(function( $ ) {
  /*
  Generic bootstrap 4 modal dialog to get plain text using ajax
  */
  $.fn.infomodal = function(title) {
    if(title===undefined || title===null ){
      title= "Info"
    }

    $("body").append(
      $("<div/>", { id: "infomodal", class: "modal fade bd-example-modal-lg", role: "dialog", tabindex: "-1", "aria-labelledby": "Info"}).append(
        $("<div/>", {class: "modal-dialog modal-lg", role: "document"}).append(
          $("<div/>", {class: "modal-content"}).append(
            // Header
            $("<div/>", {class: "modal-header"}).append(
              $("<button/>", {class: "close", "data-dismiss": "modal",  type: "button"}).html('<span aria-hidden="true">&times;</span>'),
              $("<h3/>").text(title)
            ),
            // Body
            $("<div/>", {class: "modal-body"}).append(this),
            //Footer
            $("<div/>", {class: "modal-footer"}).html('<button class="btn" data-dismiss="modal">Close</button>')                      
          )
        )
      )
    );
    
    $('#infomodal').on('hidden.bs.modal', function (){
      $('#infomodal').remove();
    });
    $('#infomodal').modal();
  };
  
  // trigger to create modal
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
  
  $('[data-toggle="tooltip"]').tooltip();
  
  $('[data-toggle="tooltip"]').on('shown.bs.tooltip', function () {
    var id = this.id;
    setTimeout(function () {
      $('#' + id).tooltip('hide'); 
    }, 2000);
  });
  
  //Tests
  $("#remove_ip").click(function(e) {
    var allowed_ips = $("#allowed_ips").val();
    console.log(allowed_ips);
  });
});