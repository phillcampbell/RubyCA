$(document).ready(function() {
	
// Support for AJAX loaded modal window.
// Focuses on first input textbox after it loads the window.
$('[data-toggle="modal"]').click(function(e) {
	e.preventDefault();
	var url = $(this).attr('href');
	if (url.indexOf('#') == 0) {
		$(url).modal('open');
	} else {
		$.get(url, function(data) {
      $('<pre/>').text(data).appendTo('.modal-body');
      $('#myModal').modal();
		}, 'text').success(function() { $('input:text:visible:first').focus(); });
	}
});
$('[data-dismiss="modal"]').click(function(e) {
  $('.modal-body').empty();  
});  
});