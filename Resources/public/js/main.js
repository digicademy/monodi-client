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

var setFocus = function(el, start) {
	var $el = $(monodi.document.getHtmlElement(el)).find('[contenteditable]').focus();
	if (!start) {
		placeCaretAtEnd($el[0]);
	}
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

var placeCaretAtEnd = function(el) {
    if (typeof window.getSelection != "undefined" && typeof document.createRange != "undefined") {
        var range = document.createRange();
        range.selectNodeContents(el);
        range.collapse(false);
        var sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);
    } else if (typeof document.body.createTextRange != "undefined") {
        var textRange = document.body.createTextRange();
        textRange.moveToElementText(el);
        textRange.collapse(false);
        textRange.select();
    }
};

//callback for delete annotated element
$(document).on('keydown', function(e) {
	var note = checkElement('note'),
		syl = checkElement('syl'),
		sbS = checkElement('sb', 'source'),
		pb = checkElement('pb'),
		sb = checkElement('sb');

	if (note || syl || sbS || pb || sb) {
		if (e.ctrlKey && e.keyCode == 75) { //ctrl+k
			var sel = monodi.document.getSelectedElement();
			monodi.document.selectElement(null);
			var $modal = $('#annotationModal').find('form').on('submit', function() {
				var $this = $(this).off('submit');
				monodi.document.newAnnot({
					ids: [sel.getAttribute('xml:id')],
					type: $this.find('select').val(),
					label: $this.find('input').val(),
					text: $this.find('textarea').val()
				});

				$modal.modal('hide');
				monodi.document.selectElement(sel);

				return false;
			}).find('input').val('').end().find('textarea').val('').end().end().find('.btn-danger').hide().end().modal('show').on('hide.annotation', function(e) {
				$(this).off('.annotation').find('form').off('submit');
			});

			return false;
		}
	}

	if (note || sbS || pb) {
		switch(e.keyCode) {
			case 32: //space
				monodi.document.newUneumeAfter();
			break;
			case 13: //enter
				monodi.document.newIneumeAfter();
			break;
		}
	}

	if (note || sbS) {
		switch(e.keyCode) {
			case 37: //left
			case 39: //right
				var prevOrNext = (e.keyCode == 37)? 'preceding' : 'following';
				monodi.document.selectNextElement(prevOrNext);
			break;
			case 8: //del
				monodi.document.deleteElement();
				return false;
			break;
		}
	}

	if (note) {
		switch(e.keyCode) {
			case 38: //up
				monodi.document.changeScaleStep(1);
			break;
			case 40: //down
				monodi.document.changeScaleStep(-1);
			break;
			case 16:  // shift
				monodi.document.newNoteAfter();
			break;
			case 66: //b
				monodi.document.toggleAccidental("f");
			break;
			case 73: //i
				monodi.document.newSourceSbAfter();
			break;
			case 74: //j
			  monodi.document.newSourceSbBefore();
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
			case 190: //.
				monodi.document.changeScaleStep(0); // This turns a dummy note into persistent one
				monodi.document.selectNextElement("following");
			break;
			case 65: //a 
				monodi.document.toggleFollowingUnpitchedLiquescent("u");
			break;
			case 68: //d
				monodi.document.toggleFollowingUnpitchedLiquescent("d");
			break;
			default: //console.log(e);
		}

		return false;
	}

	if (sbS) {
		switch(e.keyCode) {
			case 73: //i
			case 74: //j
				var temp = monodi.document.getSelectedElement();
				monodi.document.newSourcePbAfter();
				monodi.document.deleteElement(temp, true);
				setTimeout( function() {
					setFocus(monodi.document.getSelectedElement());
				}, 0);
			break;
		}
	}

	if (syl || pb || sb) {
		var caret = getCaretCharacterOffsetWithin(e.target),
			$target = $(e.target),
			text = $(e.target).text();

		switch(e.keyCode) {
			case 8: //del
				if (text == '') {
					if (syl) {
						monodi.document.selectNextElement("preceding");
						setTimeout(function() {
							setFocus(monodi.document.getSelectedElement());
						},0)
					} else {
						monodi.document.deleteElement();
					}
					return false;
				}
			break;
			case 37: //left
			case 39: //right
				caret = getCaretCharacterOffsetWithin(e.target);
				if (e.keyCode == 37 && caret == 0) {
					var prev = monodi.document.selectNextElement('preceding');
					if (prev) {
						setFocus(prev);
					}

					return false;
				}
				if (e.keyCode == 39 && caret >= text.length) {
					var next = monodi.document.selectNextElement('following');
					if (next) {
						setFocus(next, true);
					}

					return false;
				}
			break;
		}
	}

	if (syl) {
		switch (e.keyCode) {
			case 32: //space
				monodi.document.setTextContent(text.substring(0,caret), true);
				monodi.document.newSyllableAfter(text.substring(caret));
				setFocus(monodi.document.getSelectedElement(), true);
				return false;
			break;
			case 13: //enter
				monodi.document.newEditionSbAfter();
				e.preventDefault();
				setFocus(monodi.document.getSelectedElement());
			break;
			default:
				setTimeout( function() {
					var text = $(e.target).text();
					switch(text.charAt(caret)) {
						case '-':
							if ([37,39].indexOf(e.keyCode) < 0) {
								monodi.document.setTextContent(text.substring(0,caret+1), true);
								monodi.document.newSyllableAfter(text.substring(caret+1));
								setFocus(monodi.document.getSelectedElement(), true);
							}
						break;
					}
				}, 0);
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
}).on('focus', '[contenteditable]', function(e) {
  monodi.document.selectElement(e.target);
}).on('input', '[contenteditable]:not([data-editable-attribute]):not(.folioDescription)', function(e) {
	monodi.document.setTextContent($(e.target).text(), true);
}).on('input', '[contenteditable][data-editable-attribute]', function(e) {
	$target = $(e.target);
	monodi.document.setAttribute($target.attr("data-editable-attribute"), $target.text(), true, $target.attr("data-element-id"));
}).on('input', '.folioDescription[contenteditable]', function(e) {
	if (checkElement('pb')) {
		var text = $(e.target).text(),
			// We're splitting the folio description into the components folio number and recto/verso info
			components = text.match(/\s*(.*)\s*([rv])\s*$/);
		if (components) {
			monodi.document.setPbData(components[1], {r:"recto", v:"verso"}[components[2]], true);
		} else {
			monodi.document.setPbData(text.trim(), "", true);
		}
	}
}).on('focus', '[contenteditable]', function(e) {
	setTimeout( function() {
		monodi.document.selectElement(e.target);
	}, 10);
}).on('click', '.annotLabel a' , function(e) {
	var annot = $(e.target).closest('.annotLabel').data('annotation-id'),
		properties = monodi.document.getAnnotProperties(annot),
		sel = monodi.document.getSelectedElement();

	monodi.document.selectElement(null);
	var $modal = $('#annotationModal').find('form').on('submit', function() {
		var $this = $(this).off('submit');
		monodi.document.setAnnotProperties(annot, {
			type: $this.find('select').val(),
			label: $this.find('input').val(),
			text: $this.find('textarea').val()
		});

		$modal.modal('hide');
		monodi.document.selectElement(sel);

		return false;
	}).find('select').val(properties.type).end()
	.find('input').val(properties.label).end()
	.find('textarea').val(properties.text).end().end()
	.find('.btn-danger').show().end()
	.modal('show').on('hide.annotation', function(e) {
		$(this).find('form').off('submit');
		$(this).find('.btn-danger').off('click');
	}).find('.btn-danger').on('click', function(e) {
		if (confirm('Do you want to delete the Annotation?')) {
			monodi.document.deleteElement(annot, true);
		} else {
			return false;
		}
	}).end();

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

		var annotProperties = monodi.document.getAnnotProperties(annot);
		if (start === annotProperties.startid) {
			annotProperties.startid = id;
		} else {
			annotProperties.endid = id;
		}
		monodi.document.setAnnotProperties(annot, {ids: [annotProperties.startid, annotProperties.endid]});

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

$('#printContainer button').on('click', function() {
	$(this).parent().hide().children('.mei').remove();
});

$(window).on('beforeunload', function() {
	return 'Are you sure you want to close the application? All unsaved changes will be lost!';
});

$('<p class="version">v0.9.1</p>').appendTo('.footer .container');
