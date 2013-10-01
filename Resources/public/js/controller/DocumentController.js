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

		document.title = "mono:di - " + $scope.active.filename;

		$scope.showView('main');
	});

	var getParent = function(id, data) {
		var result = false;
		angular.forEach(data, function(el) {
			if (!result) {
				angular.forEach(el.documents, function(child) {
					if (child.id == id ) {
						result = el;
					}
				});

				angular.forEach(el.folders, function(child) {
					if (child.id == id ) {
						result = el;
					}
				});
			}

			if (!result && el.children_count > 0) {
				result = getParent(id, el.folders);
			}
		});

		return result;
	};
	$scope.$on('saveDocument', function(e, data) {
		var temp, doc;
		if ($scope.online && $scope.access_token) {
			if (data) {
				doc = localStorage['document' + data.id];
				temp = $scope.active;
				$scope.setActive(JSON.parse(doc));
			} else {
				$scope.active.content = monodi.document.getSerializedDocument();
			}

			var putObject = {
				filename: $scope.active.filename,
				content: $scope.active.content,
				folder: getParent($scope.active.id, $scope.documents).id
			};

			$http.put(baseurl + 'api/v1/documents/' + $scope.active.id + '.json?access_token=' + $scope.access_token, angular.toJson(putObject))
				.error(function(data, status) {
					alert('The document could not be saved on the server. Please try again or contact the administrator (error-code ' + status + ').');
				});

			if (data) {
				$scope.setActive(temp);
				if (localStorage['syncList']) {
					localStorage['syncList'] = localStorage['syncList'].replace(' ' + $scope.active.id + ',', '');
				}
			}
		} else if (!data) {
			$scope.saveToSyncList();
		}

		if (!data) {
			$('#savedModal').modal('show');
		}
	});

	$scope.$on('newDocument', function(e, data) {
		monodi.document = new MonodiDocument({
			staticStyleElement	: document.getElementById("staticStyle"),
			dynamicStyleElement	: document.getElementById("dynamicStyle"),
			musicContainer		: document.getElementById("musicContainer"),
			xsltUrl				: "/bundles/digitalwertmonodiclient/js/monodi/mei2xhtml.xsl"
		});

		var $text = $('#newDocumentText');
		if (data.settext) {
			monodi.document.newDocument($text.val(), function(problemLine, problemLineNumber){
				alert( "Line " + problemLineNumber + " does not follow the expected syntax:\n\n" + problemLine + "\n\nA fallback method will be used for generating the document");
				return true;
			});
		} else {
			monodi.document.newDocument();
		}
		$text.val('');

		$scope.setActive({ content: monodi.document.getSerializedDocument() });
		document.title = "mono:di - unsaved document";

		$scope.showView('main');
	});

	$scope.$on('saveNewDocument', function() {
		var temp;

		monodi.document.selectElement(null);
		if ($scope.active.id) {
			temp = $scope.active;
			$scope.setActive({
				filename: temp.filename,
				title: temp.title
			});
        }
		var $files = $('.files.container').addClass('chooseDirectory').find('.fileviewToggle .btn:first-child').trigger('click').end().fadeIn(),
			$bg = $('<div class="modal-backdrop fade in"></div>').insertAfter($files).on('click', function(e) {
				if (!$(e.target).hasClass('saveNewDocumentHere')) {
					$scope.setActive(temp);
				}
				$files.fadeOut( function() {
					$(this).removeClass('chooseDirectory');
					$bg.remove();
				});
		});
	});

	$scope.$on('syncDocument', function(e, data) {
		$scope.$broadcast('saveDocument', { id: data.id });
	});

	$scope.$on('syncNewDocument', function(e, data) {
		var parent = getParent(data.id, $scope.syncDocuments),
			parentId = parent.id,
			temp = { id: 0 };
		if ((parentId + '').indexOf('temp') > -1) {
			while (temp.id != parentId && (parentId + '').indexOf('temp') > -1) {
				temp = parent;
				parent = getParent(parentId, $scope.syncDocuments);
				parentId = parent.id;
			}

			if ((parentId + '').indexOf('temp') < 0) {
				$scope.postNewFolderToServer(parent.path, temp.title, temp.id, function() {
					$scope.$broadcast('syncNewDocument', { id: data.id });
				});
			}
		} else {
			$scope.$broadcast('postNewDocument', { id: data.id });
		}
	});

	$scope.$on('postNewDocument', function(e, data) {
		if ($scope.online && $scope.access_token) {
			if (data) {
				var temp = $scope.active,
					doc = localStorage['document' + data.id];
				$scope.setActive(JSON.parse(doc));
			} else {
				$scope.active.content = monodi.document.getSerializedDocument();
			}
			var putObject = {
				filename: $scope.active.filename,
				content: $scope.active.content,
				folder: getParent($scope.active.id, $scope.documents).id
			};

			$http.post(baseurl + 'api/v1/documents/?access_token=' + $scope.access_token, angular.toJson(putObject))
				.success( function(response, status, headers) {
					var newId = headers['x-ressourceident'],
						id = $scope.active.id;
					if (data) {
						id = data.id;
					}

					$scope.active.id = newId;

					$scope.setNewId(id, newId);
					if (localStorage['syncList']) {
						localStorage['syncList'] = localStorage['syncList'].replace(' ' + id + ',', '');
					}

					$scope.$emit('reloadDocuments');
				}).error(function(data, status) {
					alert('The document could not be saved on the server. Please try again or contact the administrator (error-code ' + status + ').');
				});

			if (data) {
				$scope.setActive(temp);
			}
		} else {
			if (!data) {
				$scope.saveToSyncList();
			}
		}
	});

	monodi.document = new MonodiDocument({
		staticStyleElement	: document.getElementById("staticStyle"),
		dynamicStyleElement	: document.getElementById("dynamicStyle"),
		musicContainer		: document.getElementById("musicContainer"),
		xsltUrl				: "/bundles/digitalwertmonodiclient/js/monodi/mei2xhtml.xsl"
	});

	var typesrc = monodi.document.ANNOTATION_TYPES || {};
	types = '<p><select>';
	for (var type in typesrc) {
		types += '<option value="' + type + '">' + typesrc[type].label + '</option>';
	}
	$('#annotationModal').find('input').parent().before(types + '</select></p>');

}