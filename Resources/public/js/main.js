$('.fileviewToggle').on('click', '.btn', function() {
	var i = $(this).parent().children().removeClass('active').end().end().addClass('active').index();
	$('.fileviews').children().hide().eq(i).show();
});

$('.fileStructure').on('click', '.btn-link', function() {
	$(this).toggleClass('showChildren');
});

var checkElement = function(el, attr) {
	var result = false;
	if (monodi && monodi.document) {
		var sel = monodi.document.getSelectedElement();
		if (sel && sel.nodeName == el) {
			result = true;
		}

		if (attr && result) {
			if (!sel.getAttribute(attr)) {
				result = false;
			}
		}
	}
	return result;
};

var getCaretCharacterOffsetWithin = function (element) {
    var caretOffset = 0;
    if (typeof window.getSelection != "undefined") {
        var range = window.getSelection().getRangeAt(0);
        var preCaretRange = range.cloneRange();
        preCaretRange.selectNodeContents(element);
        preCaretRange.setEnd(range.endContainer, range.endOffset);
        caretOffset = preCaretRange.toString().length;
    } else if (typeof document.selection != "undefined" && document.selection.type != "Control") {
        var textRange = document.selection.createRange();
        var preCaretTextRange = document.body.createTextRange();
        preCaretTextRange.moveToElementText(element);
        preCaretTextRange.setEndPoint("EndToEnd", textRange);
        caretOffset = preCaretTextRange.text.length;
    }
    return caretOffset;
};

//callback for delete annotated element
$(document).on('keydown', function(e) {
	var note = checkElement('note'),
		syl = checkElement('syl'),
		sbS = checkElement('sb', 'source'),
		pb = checkElement('pb');

	if (note || syl || sbS || pb) {
		if (e.ctrlKey && e.keyCode == 75) {
			var sel = monodi.document.getSelectedElement();
			monodi.document.selectElement(null);
			var $modal = $('#annotationModal').find('form').on('submit', function() {
				var $this = $(this);
				monodi.document.newAnnot({
					ids: [sel.getAttribute('xml:id')],
					type: $this.find('select').val(),
					label: $this.find('input').val(),
					text: $this.find('textarea').val()
				});

				$modal.modal('hide');

				return false;
			}).find('input').val('').end().find('textarea').val('').end().end().modal('show');
		}
	}

	if (note || sbS || pb) {
		switch(e.keyCode) {
			case 37: //left
			case 39: //right
				var prevOrNext = (e.keyCode == 37)? 'preceding' : 'following';
				monodi.document.selectNextElement(prevOrNext);
			break;
			case 32: //space
				monodi.document.newUneumeAfter();
			break;
			case 13: //enter
				monodi.document.newIneumeAfter();
			break;
			case 8: //del
				monodi.document.deleteElement();
			break;
			case 75: //k
		}
	}

	if (note) {
		switch(e.keyCode) {
			case 38: //up
			case 40: //down
				var change;
				if (e.shiftKey) {
					change = (e.keyCode == 38)? 'u' : 'd';
					monodi.document.setIntm(change);
				} else {
					change = (e.keyCode == 38)? 1 : -1;
					monodi.document.changeScaleStep(change);
				}
			break;
			case 173: //- (Lin)
			case 189: //- (Mac)
				monodi.document.newNoteAfter();
			break;
			case 66: //b
				monodi.document.toggleAccidental("f");
			break;
			case 73: //i
				monodi.document.newSourceSbAfter();
			break;
			case 78: //n
				monodi.document.toggleAccidental("n");
			break;
			case 83: //s
				monodi.document.toggleAccidental("s");
			break;
			case 79: //o
			case 81: //q
			case 187: //´
			case 188: //,
				var pitchClass = (function() {
					switch(e.keyCode) {
						case 79: return 'oriscus';
						case 81: return 'quilisma';
						case 187:
						case 188:
							return 'apostropha';
					}
				})();
				monodi.document.togglePerformanceNeumeType(pitchClass);
			break;
			case 76: //l
				monodi.document.toggleLiquescence();
			break;
			default: //console.log(e);
		}

		return false;
	}

	if (sbS) {
		switch(e.keyCode) {
			case 73: //i
				var temp = monodi.document.getSelectedElement();
				monodi.document.newSourcePbAfter();
				monodi.document.deleteElement(temp, true);
			break;
		}
	}

	if (syl) {
		var caret = getCaretCharacterOffsetWithin(e.target);
			$target = $(e.target),
			text = $(e.target).text(),
			open = text.indexOf('<'),
			close = text.indexOf('>');

		switch(e.keyCode) {
			case 9: //tab
				var dir = (e.shiftKey)? 'preceding' : 'following';
				var $new = $(monodi.document.getHtmlElement(monodi.document.selectNextElement(dir)));
				if ($new.length) {
					setTimeout( function() {
						$new.find('[contenteditable]').focus();
					}, 10);
				}
			break;
			case 37: //left
			case 39: //right
				caret = getCaretCharacterOffsetWithin(e.target);
				if (e.keyCode == 37 && caret == 0) {
					var $prev = $(monodi.document.getHtmlElement(monodi.document.selectNextElement('preceding')));
					if ($prev.length) {
						$prev.find('[contenteditable]').focus();
					}
				}
				if (e.keyCode == 39 && caret >= text.length) {
					var $next = $(monodi.document.getHtmlElement(monodi.document.selectNextElement('following')));
					if ($next.length) {
						$next.find('[contenteditable]').focus();
					}
				}
			break;
			case 32: //space
				if (open < 0 || close < 0 || caret > close) {
					monodi.document.setSylText(text.substring(0,caret));
					$target.data('saved', true);
					monodi.document.newSyllableAfter(text.substring(caret+1));
					$(monodi.document.getHtmlElement(monodi.document.selectNextElement('following'))).find('[contenteditable]').focus();
				}
			break;
			case 13: //enter
				monodi.document.newEditionSbAfter();
			break;
			default:
				if (open < 0 || close < 0 || caret > close) {
					setTimeout( function() {
						var text = $(e.target).text();
						switch(text.charAt(caret)) {
							case '-':
								monodi.document.setSylText(text.substring(0,caret+1));
								$target.data('saved', true);
								monodi.document.newSyllableAfter(text.substring(caret+1));
								$(monodi.document.getHtmlElement(monodi.document.selectNextElement('following'))).find('[contenteditable]').focus();
							break;
							case '|':
							break;
						}
					}, 0);
				}
		}
	}
}).on('click', '#musicContainer', function(e) {
	var $target = $(e.target);
	if ($(e.target).hasClass('_mei')) {
		monodi.document.selectElement(e.target);
	} else {
		$target = $target.closest('._mei');
		if ($target.length) { monodi.document.selectElement($target[0]); }
	}
}).on('focusout', '.syl span[contenteditable]', function(e) {
	if (checkElement('syl')) {
		var $target = $(e.target);
		if (!$target.data('saved')) {
			//monodi.document.setSylText($(e.target).text());
		}
	}
}).on('focusout', '.sb.edition[contenteditable]', function(e) {
	if (checkElement('sb')) {
		monodi.document.setSbLabel($(e.target).text());
	}
}).on('focusout', '.folioDescription[contenteditable]', function(e) {
	if (checkElement('pb')) {
		var text = $(e.target).text(),
			end = text.charAt(text.length - 1);
		if (end == 'r' || end == 'v') {
			text = text.substr(0, text.length - 1);
		} else {
			end = '';
		}

		monodi.document.setPbData(text, end);
	}
}).on('click', '.annotLabel a' , function(e) {
	var annot = $(e.target).closest('.annotLabel').data('annotation-id'),
		properties = monodi.document.getAnnotProperties(annot);

	var $modal = $('#annotationModal').find('form').on('submit', function() {
		var $this = $(this);
		monodi.document.setAnnotProperties(annot, {
			type: $this.find('select').val(),
			label: $this.find('input').val(),
			text: $this.find('textarea').val()
		});

		$modal.modal('hide');

		return false;
	}).find('input').val(properties.label).end().find('textarea').val(properties.text).end().end().modal('show');

	return false;
}).on('click', '.annotSelectionExtender', function(e) {
	var $target = $(e.target),
		annot = $target.closest('.annotLabel').data('annotation-id'),
		start = $target.closest('[id]').attr('id');
	$('#musicContainer').css('cursor', 'copy').on('click.annot', function(e) {
		var $target = $(e.target),
			id = $target.attr('id');
		if (!id) {
			id = $target.closest('[id]').attr('id');
		}

		monodi.document.setAnnotProperties(annot, { ids: [start, id] });

		$(this).off('.annot').removeAttr('style');
		return false;
	});

	$('body').on('keydown.annot', function(e) {
		$('body').off('.annot').removeAttr('style');
		$('#musicContainer').off('.annot').removeAttr('style');
		return false;
	});

	return false;
});