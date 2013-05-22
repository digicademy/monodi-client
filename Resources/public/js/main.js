$('#login').on('click', '.forgot', function() {
	$(this).closest('.modal').modal('hide');
	$('#forgot').modal('show');

	return false;
});//.modal('show');

$('.fileviewToggle').on('click', '.btn', function() {
	var i = $(this).parent().children().removeClass('active').end().end().addClass('active').index();
	$('.fileviews').children().hide().eq(i).show();
});

$('.fileStructure').on('click', '.btn-link', function() {
	$(this).toggleClass('showChildren');
});

$('.nav').on('click', 'li', function() {
	var $views = $('.views').children();
	var $show = $views.eq($(this).index());
	if ($show.length) {
		$views.hide();
		$show.show();
	}
});

$('.files').show();