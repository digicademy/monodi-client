$('.fileviewToggle').on('click', '.btn', function() {
	var i = $(this).parent().children().removeClass('active').end().end().addClass('active').index();
	$('.fileviews').children().hide().eq(i).show();
});

$('.fileStructure').on('click', '.btn-link', function() {
	$(this).toggleClass('showChildren');
});

var checkElement = function(el) {
	return (monodi && monodi.document && monodi.document.getSelectedElement())? monodi.document.getSelectedElement().nodeName == el : false;
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

$(document).on('keydown', function(e) {
	if (checkElement('note')) {
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
			case 37: //left
			case 39: //right
				var prevOrNext = (e.keyCode == 37)? 'preceding' : 'following';
				monodi.document.selectNextElement(prevOrNext);
			break;
			case 173: //- (Lin)
			case 189: //- (Mac)
				monodi.document.newNoteAfter();
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
			case 66: //b
        monodi.document.toggleAccidental("f");
      break;
      case 83: //s
        monodi.document.toggleAccidental("s");
			break;
			case 78: // n
			  monodi.document.toggleAccidental("n");
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
			default: console.log(e);
		}

		return false;
	}

	if (checkElement('syl')) {
		var caret;

		switch(e.keyCode) {
			case 37: //left
			case 39: //right
				caret = getCaretCharacterOffsetWithin(e.target);
				if (e.keyCode == 37 && caret == 0) {
					var $prev = $(monodi.document.getHtmlElement(monodi.document.selectNextElement('preceding')));
					if ($prev.length) {
						$prev.focus();
					}
				}
				if (e.keyCode == 39 && caret >= $(e.target).text().length) {
					var $next = $(monodi.document.getHtmlElement(monodi.document.selectNextElement('following')));
					if ($next.length) {
						$next.focus();
					}
				}
			break;
			case 32: //Space
			case 173: //- (Lin)
			case 189: //- (Mac)
				var $target = $(e.target),
					text = $(e.target).text(),
					open = text.indexOf('<'),
					close = text.indexOf('>');
				caret = getCaretCharacterOffsetWithin(e.target);

				if (open < 0 || close < 0 || caret > close) {
					monodi.document.setSylText(text.substring(0,caret) + (e.keyCode == 32? '' : '-'));
					$target.data('saved', true);
					monodi.document.newSyllableAfter(text.substring(caret));
				}
			break;
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
});