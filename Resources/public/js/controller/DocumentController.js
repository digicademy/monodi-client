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

	var getParentId = function(id, data) {
        var result = false;
        angular.forEach(data, function(el) {
            if (!result && el.document_count > 0) {
                var path = el.path;
                angular.forEach(el.documents, function(child) {
                    if (child.id == id ) {
                        result = el.id;
                    }
                });
            }

            if (!result && el.children_count > 0) {
                result = getParentId(id, el.folders);
            }
        });

        return result;
    };
	$scope.$on('saveDocument', function() {
		if ($scope.online && $scope.access_token) {
			$scope.active.content = monodi.document.getSerializedDocument();

			var putObject = {
				filename: $scope.active.filename,
				content: $scope.active.content,
				folder: getParentId($scope.active.id, $scope.documents)
			};

			$http.put(baseurl + 'api/v1/documents/' + $scope.active.id + '.json?access_token=' + $scope.access_token, angular.toJson(putObject));
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

		monodi.document = new MonodiDocument({
			staticStyleElement	: document.getElementById("staticStyle"),
			dynamicStyleElement	: document.getElementById("dynamicStyle"),
			musicContainer		: document.getElementById("musicContainer"),
			xsltUrl				: "/bundles/digitalwertmonodiclient/js/monodi/mei2xhtml.xsl"
		});

		monodi.document.newDocument();
		$scope.setActive({ content: monodi.document.getSerializedDocument() });

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

	$scope.$on('postNewDocument', function() {
		if ($scope.online && $scope.access_token) {
            var putObject = {
                filename: $scope.active.filename,
                content: $scope.active.content,
                folder: getParentId($scope.active.id, $scope.documents)
            };

            $http.post(baseurl + 'api/v1/documents/?access_token=' + $scope.access_token, angular.toJson(putObject));
        } else {
            $scope.saveToSyncList();
        }
	});
}