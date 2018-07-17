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
              $("<h3/>").text(title),
              $("<button/>", {class: "close", "data-dismiss": "modal",  type: "button"}).html('<span aria-hidden="true">&times;</span>')
            ),
            // Body
            $("<div/>", {class: "modal-body"}).append(this),
            //Footer
            $("<div/>", {class: "modal-footer"}).html('<button type="button" class="btn btn-primary" data-dismiss="modal">Close</button>')                      
          )
        )
      )
    );
    
    $('#infomodal').on('hidden.bs.modal', function (){
      $('#infomodal').remove();
    });
    $('#infomodal').modal();
  };
  
  $('a#download').click(function(){
    setTimeout(function() {
      window.location.replace("/admin/certificates");
      }, 700);
  });
  
  
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
  
  // BS Tooltip
  $('[data-toggle="tooltip"]').tooltip();
  $('[data-toggle="tooltip"]').on('shown.bs.tooltip', function () {
    var id = this.id;
    setTimeout(function () {
      $('#' + id).tooltip('hide'); 
    }, 2000);
  });
  
  //Tests
  $('.ajax-get-file').click(function(e){
    e.preventDefault();
    var url = $(this).closest('form').attr('action');
    
    $.ajax({
      type: "POST",
      url: url,
      data: $(this).closest('form').serialize(),
      success: function(response, status, xhr) {
        
        var index = url.lastIndexOf("/") + 1;
        var filename = url.substr(index);
        
        var disposition = xhr.getResponseHeader('Content-Disposition');
        if (disposition && disposition.indexOf('attachment') !== -1) {
            var filenameRegex = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/;
            var matches = filenameRegex.exec(disposition);
            if (matches != null && matches[1]) filename = matches[1].replace(/['"]/g, '');
        }

        var type = xhr.getResponseHeader('Content-Type');
        var blob = new Blob([response], { type: type });
        
        console.log(type);

        if (typeof window.navigator.msSaveBlob !== 'undefined') {
            // IE workaround for "HTML7007: One or more blob URLs were revoked by closing the blob for which they were created. These URLs will no longer resolve as the data backing the URL has been freed."
            window.navigator.msSaveBlob(blob, filename);
        } else {
            var URL = window.URL || window.webkitURL;
            var downloadUrl = URL.createObjectURL(blob);

            if (filename) {
                // use HTML5 a[download] attribute to specify filename
                var a = document.createElement("a");
                // safari doesn't support this yet
                if (typeof a.download === 'undefined') {
                    window.location = downloadUrl;
                } else {
                    a.href = downloadUrl;
                    a.download = filename;
                    document.body.appendChild(a);
                    a.click();
                }
            } else {
                window.location = downloadUrl;
            }

            setTimeout(function () { URL.revokeObjectURL(downloadUrl); }, 100); // cleanup
        }
      }
    });    
  });  
});