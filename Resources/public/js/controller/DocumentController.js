function DocumentCtrl($scope, $http) {
	$scope.$on('openDocument', function() {
		initMonodiDocument($scope.active.content);

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
			if (($scope.active.id + '').indexOf('temp') < 0) {
				if (data) {
					doc = $scope.getLocal('document' + data.id);
					temp = JSON.parse($scope.active);
					$scope.setActive(doc);
				} else {
					$scope.active.content = monodi.document.getSerializedDocument();
				}

				var putObject = {
					filename: $scope.active.filename,
					content: $scope.active.content,
					folder: getParent($scope.active.id, $scope.documents).id
				};

				$scope.showLoader();
				$http.put(baseurl + 'api/v1/documents/' + $scope.active.id + '.json?access_token=' + $scope.access_token, angular.toJson(putObject))
					.success(function() {
						var id = $scope.active.id;
						if (data) {
							id = data.id;
						}

						$scope.removeFromSyncList(id);
						$scope.$emit('sync');

						$scope.hideLoader();
					})
					.error(function(data, status) {
						$scope.hideLoader();
						$scope.checkOnline(status);
						if (status != 0) {
							alert('The document could not be saved on the server. Please try again or contact the administrator (error-code ' + status + ').');
						}

						if (!data) {
							$scope.saveToSyncList();
						}
					});

				if (data) {
					$scope.setActive(temp);
				}
			} else {
				$scope.$broadcast('postNewDocument', data);
			}
		} else if (!data) {
			$scope.saveToSyncList();
		}

		if (!data) {
			$scope.addToDocumentList($scope.active.id, $scope.active);
			$('#savedModal').modal('show');
		}
	});

	$scope.$on('newDocument', function(e, data) {
		initMonodiDocument();

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
				title: temp.title.replace(/.mei$/,'')
			});
        }
		var $files = $('.files.container').addClass('chooseDirectory').find('.fileviewToggle .btn:first-child').trigger('click').end().fadeIn(),
			$bg = $('<div class="modal-backdrop fade in"></div>').insertAfter($files).on('click', function(e) {
				if (!$(e.target).hasClass('saveNewDocumentHere')) {
					if (temp) {
						$scope.setActive(temp);
					}
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
			var temp, doc;
			if (data) {
				temp = $scope.active;
				doc = JSON.parse($scope.getLocal('document' + data.id));
				$scope.setActive(doc);
			} else {
				$scope.active.content = monodi.document.getSerializedDocument();
			}
			var putObject = {
				filename: $scope.active.filename,
				content: $scope.active.content,
				folder: getParent($scope.active.id, $scope.documents).id
			};

			$scope.showLoader();
			$http.post(baseurl + 'api/v1/documents/?access_token=' + $scope.access_token, angular.toJson(putObject))
				.success( function(response, status, headers) {
					var newId = headers()['x-ressourceident'],
						id = $scope.active.id;
					if (data) {
						id = data.id;
					}

					$scope.setNewId(id, newId);
					$scope.removeFromSyncList(id);

					$scope.hideLoader();

					$scope.$emit('reloadDocuments');
					$scope.$emit('sync');
				}).error(function(response, status) {
					$scope.hideLoader();
					$scope.checkOnline(status);
					if (status == 400 && response.children.filename.errors && response.children.filename.errors[0].indexOf('This value is already used') > -1) {
						var id = $scope.active.id;
						if (data) {
							id = data.id;
						}

						doc.filename = prompt('The filename ' + doc.filename + ' already exists in this folder on the server. Please rename your file.');
						$scope.setLocal('document' + id, JSON.stringify(doc));

						$scope.$emit('sync');
					} else if (status != 0) {
						alert('File could not be saved on server (error-code ' + status + ') but has been saved locally.');
					}

					if (!data) {
						$scope.saveToSyncList();
					}
				});

			if (data) {
				$scope.setActive(temp);
			}
		} else {
			if (!data) {
				$scope.saveToSyncList();
			}
		}

		$scope.addToDocumentList($scope.active.id, $scope.active);
	});

	var initMonodiDocument = function(meiString) {
		monodi.document = new MonodiDocument({
			staticStyleElement	: document.getElementById("staticStyle"),
			dynamicStyleElement	: document.getElementById("dynamicStyle"),
			musicContainer		: document.getElementById("musicContainer"),
			xsltUrl				: "/bundles/digitalwertmonodiclient/js/monodi/mei2xhtml.xsl",
			meiString			: meiString
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
	};

	initMonodiDocument();

	var typesrc = monodi.document.ANNOTATION_TYPES || {};
	types = '<p><select>';
	for (var type in typesrc) {
		types += '<option value="' + type + '">' + typesrc[type].label + '</option>';
	}
	$('#annotationModal').find('input').parent().before(types + '</select></p>');

}