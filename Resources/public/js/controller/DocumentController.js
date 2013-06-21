function DocumentCtrl($scope, $http) {
	$scope.$on('openDocument', function() {
		monodi.document = new MonodiDocument({
			staticStyleElement	: document.getElementById("staticStyle"),
			dynamicStyleElement	: document.getElementById("dynamicStyle"),
			musicContainer		: document.getElementById("musicContainer"),
			xsltUrl				: "/bundles/digitalwertmonodiclient/js/monodi/mei2xhtml.xsl",
			meiString			: $scope.active.content
		});

		monodi.document.addCallback('deleteAnnotatedElement', function(data) {
			return confirm('Do you want to delete the ' + data.length + ' Annotations associated with this element?');
		});

		monodi.document.addCallback("updateView",function(element){
			var offset = $(element).offset().top - $(window).scrollTop();

			if(offset > window.innerHeight || offset < 0){
				element.scrollIntoView(offset > 0);
			}
		});

		var typesrc = monodi.document.ANNOTATION_TYPES || {};
		types = '<p><select>';
		for (var type in typesrc) {
			types += '<option value="' + type + '">' + typesrc[type].label + '</option>';
		}
		$('#annotationModal').find('input').parent().before(types + '</select></p>');

		$scope.showView('main');
	});

	$scope.$on('saveDocument', function() {
		if ($scope.online && $scope.access_token) {
			$scope.active.content = monodi.document.getSerializedDocument();
			$http.put(baseurl + 'api/v1/documents/' + $scope.active.id + '.json?access_token=' + $scope.access_token, angular.toJson($scope.active)).success(function (data) {
				console.log(data);
			});
		} else {
			$scope.saveToSyncList();
		}

		$('#savedModal').modal('show');
	});

	$scope.$on('newDocument', function() {
		if ($scope.active) {
			if (!confirm('Dismiss open document?')) {
				return;
			}
		}

		$scope.setActive({
			content: '<?xml version="1.0" encoding="UTF-8"?>\
<mei xmlns="http://www.music-encoding.org/ns/mei">\
  <meiHead>\
	<fileDesc>\
	  <titleStmt>\
		<title/>\
	  </titleStmt>\
	  <pubStmt/>\
	  <sourceDesc>\
		<source/>\
	  </sourceDesc>\
	</fileDesc>\
  </meiHead>\
  <music>\
	<body>\
	  <mdiv>\
		<score>\
		  <section>\
			<staff>\
			  <layer>\
				<sb label=""/>\
				<syllable>\
				  <syl></syl>\
				</syllable>\
			  </layer>\
			</staff>\
		  </section>\
		</score>\
	  </mdiv>\
	</body>\
  </music>\
</mei>'
		});

		$scope.$broadcast('openDocument');
		$scope.showView('main');
	});

	$scope.$on('saveNewDocument', function() {
		var $files = $('.files.container').addClass('chooseDirectory').find('.fileviewToggle .btn:first-child').trigger('click').end().fadeIn(),
			$bg = $('<div class="modal-backdrop fade in"></div>').insertAfter($files).on('click', function() {
				$files.fadeOut( function() {
					$(this).removeClass('chooseDirectory');
					$bg.remove();
				});
		});
	});
}