function DocumentListCtrl($scope, $http) {
	$scope.toggle = function() {
		var $checkboxes = $('.fileList input[type="checkbox"]');
		if ($checkboxes.first().prop('checked') == true) {
			$checkboxes.prop('checked', true);
		} else {
			$checkboxes.prop('checked', false);
		}
	};

    $scope.deleteDocument = function(id) {
        $scope.getDocument(id, function() {
            $scope.removeLocal(id);

            if (this.id.indexOf('temp') < 0) {
                //delete request
            }
        });
    };

	$scope.openDocument = function(id) {
		$scope.setInfoDocument(id);
		$scope.$emit('openDocumentRequest', { id: id });
	};

	$scope.saveLocal = function(id) {
		$scope.getDocument(id, function() {
			localStorage['document' + id] = JSON.stringify(this);
			var documentList = localStorage['documentList'];
			if (documentList) {
				if (documentList.indexOf(' ' + id + ',') < 0) {
					localStorage['documentList'] += ' ' + id + ',';
				}
			} else {
				localStorage['documentList'] = ' ' + id + ',';
			}
			$scope.setLocal(id, true);
		});
	};

	$scope.removeLocal = function(id) {
		localStorage.removeItem('document' + id);
		var documentList = localStorage['documentList'];
		if (documentList) {
			localStorage['documentList'] = documentList.replace(' ' + id + ',', '');
		}
		$scope.setLocal(id, false);
	};

	$scope.documentinfo = function(id) {
		$scope.setInfoDocument(id);
		$scope.showDocumentInfo();
	};

	$scope.addFolder = function(path) {
		$scope.createFolder.path = path;
		$('#createFolderModal').modal('show');
	};

	var addFolder = function(documents, folder, pathParts, level) {
		var path = '',
			found = false;

		if (pathParts) {
			for (var i = 0; i <= level; i++) {
				path += pathParts[i] + '/';
			}
			path = path.slice(0, - 1);
			level++;
		}

		angular.forEach(documents, function(el) {
			if (el.path == path) {
				if (level == pathParts.length) {
					el.children_count++;
                    folder.root = el.id;
                    folder.path = path + '/' + folder.path;
					el.folders.push(folder);
					return true;
				}

				if (!found && el.children_count > 0) {
					found = addFolder(el.folders, folder, pathParts, level);
				}
			}
		});

		return found;
	};
	$scope.createFolder = function(filename) {
		var path = $scope.createFolder.path,
			pathParts = (path)? path.split('/') : false,
            id = 'temp' + new Date().getTime(),
			folder = {
                id: id,
				children_count: 0,
				document_count: 0,
				documents: [],
				folders: [],
				path: filename.toLowerCase().replace(' ', '_'),
				root: id,
				title: filename
			};

        if (pathParts) {
            addFolder($scope.documents, folder, pathParts, 0);
        } else {
            $scope.documents.push(folder);
        }

        //postNewFolderToServer
		$('#createFolderModal').modal('hide');
	};

	var addFile = function(documents, file, pathParts, level) {
		var path = '',
			found = false;
		for (var i = 0; i <= level; i++) {
			path += pathParts[i] + '/';
		}
		path = path.slice(0, - 1);
		level++;

		angular.forEach(documents, function(el) {
			if (el.path == path) {
				if (level == pathParts.length) {
					el.document_count++;
					el.documents.push(file);
                    $scope.files.push(file);
					return true;
				}

				if (!found && el.children_count > 0) {
					found = addFile(el.folders, file, pathParts, level);
				}
			}
		});

		return found;
	};
	$scope.saveNewDocumentHere = function(path) {
		var error = false;
		if (!$scope.active.filename) {
			$('#fileName').focus();
			error = true;
		}

		if (!error) {
			var pathParts = path.split('/');
			$scope.active.path = path;

			$scope.active.content = monodi.document.getSerializedDocument();
			$scope.active.id = 'temp' + new Date().getTime();

			addFile($scope.documents, $scope.active, pathParts, 0);

			localStorage['documents'] = JSON.stringify($scope.documents);
            localStorage['files'] = JSON.stringify($scope.files);
			$scope.setLocal($scope.active.id, true);

			$scope.postNewToServer();

			$('.files.container').hide().removeClass('chooseDirectory');
			$('.modal-backdrop').remove();
			$('#savedModal').modal('show');
		}
	};
};