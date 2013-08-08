function AppCtrl($scope, $http) {
    $http.defaults.headers.common['Accept'] = 'application/json';
    $scope.online = navigator.onLine;
    $scope.access_token = false;
    $scope.refresh_token = false;
    $scope.documents = [];
    $scope.active = false;
    $scope.info = false;

    if (window.addEventListener) {
        $scope.setOnlineStatus = function() {
            $scope.online = navigator.onLine;

            if (!navigator.onLine) {
                access_token = false;
            } else {
                $scope.$broadcast('sync');
            }
        };

        window.addEventListener("online", $scope.setOnlineStatus, false);
        window.addEventListener("offline", $scope.setOnlineStatus, false);
    }

    $scope.$on('sync', function() {
        if ($scope.online && $scope.access_token) {
            var syncList = localStorage['syncList'];
            if (syncList) {
                $scope.syncDocuments = $scope.documents;
                angular.forEach(syncList.split(','), function(id) {
                    id = id.trim();
                    if (localStorage['document' + id]) {
                        if ((id + '').indexOf('temp') < 0) {
                            $scope.$broadcast('syncDocument', { id: id });
                        } else {
                            $scope.$broadcast('syncNewDocument', { id: id });
                        }
                    }
                });
            }
        }
    });

    var filterFiles = function(documents) {
        var result = [];
        angular.forEach(documents, function(el) {
            if (el.document_count > 0) {
                var path = el.path;
                angular.forEach(el.documents, function(el) {
                    el.path = path;
                    result.push(el);
                });
            }

            if (el.children_count > 0) {
                var temp = filterFiles(el.folders);
                result = result.concat(temp);
            }
        });

        return result;
    };
    $scope.$on('reloadDocuments', function() {
        if ($scope.online && $scope.access_token) {
            $http.get(baseurl + 'api/v1/metadata.json?access_token=' + $scope.access_token).success(function (data) {
                $scope.documents = data;
                $scope.files = filterFiles(data);
                localStorage['documents'] = JSON.stringify($scope.documents);
                localStorage['files'] = JSON.stringify($scope.files);
            });
        } else if (localStorage['documents'] && localStorage['files']) {
            $scope.documents = JSON.parse(localStorage['documents']);
            $scope.files = JSON.parse(localStorage['files']);
        } else if (!$scope.online) {
            alert('A connection to the server is not available and no files are locally cached.');
        }

        var documentList = localStorage['documentList'];
        if (documentList) {
            angular.forEach(documentList.split(','), function(el) {
                id = el.trim();
                if (id > 0) {
                    $scope.setLocal(id, true);
                }
            });
        }
    });

    $scope.getDocument = function(id, callback) {
        if ($scope.online && $scope.access_token) {
            $http.get(baseurl + 'api/v1/documents/' + id + '.json?access_token=' + $scope.access_token).success(function (data) {
                data.content = data.content
                callback.bind(data)();
            });
        } else if (localStorage['document' + id]) {
            callback.bind(JSON.parse(localStorage['document' + id]))();
        } else if (!$scope.online) {
            alert('You are working offline and the ressource is locally not available.');
        } else {
            alert('Please login to get the ressource from the server.')
        }
    };

    var removeDocument = function(id, data) {
        var removed = false;
        angular.forEach(data, function(el) {
            if (!removed && el.document_count > 0) {
                angular.forEach(el.documents, function(child, i) {
                    if (child.id == id ) {
                        el.document_count--;
                        el.documents.splice(i,1);
                    }
                });
            }

            if (!removed && el.children_count > 0) {
                removed = removeDocument(id, el.folders);
            }
        });

        return removed;
    };
    $scope.deleteDocument = function(id, callback) {
        removeDocument(id, $scope.documents);
        angular.forEach($scope.files, function(el, i) {
            if (el.id == id) {
                $scope.files.splice(i,1);
            }
        });

        localStorage['documents'] = JSON.stringify($scope.documents);
        localStorage['files'] = JSON.stringify($scope.files);

        if ((id + '').indexOf('temp') < 0) {
            $http['delete'](baseurl + 'api/v1/documents/' + id + '.json?access_token=' + $scope.access_token).success( function() {
                if (callback) callback();
            });
        }
    };

    $scope.newDocument = function(settext) {
        $scope.$broadcast('newDocument', { settext: settext });
    };

    $scope.saveDocument = function() {
        if (!$scope.active) {
            alert('No active document!');
        } else if ($scope.active.id) {
            $scope.$broadcast('saveDocument');
        } else {
            $scope.$broadcast('saveNewDocument');
        }
    };

    $scope.saveNewDocument = function() {
        if (!$scope.active) {
            alert('No active document!');
        } else {
            $scope.$broadcast('saveNewDocument');
        }
    };

    $scope.saveToSyncList = function() {
        var id = $scope.active.id;
        localStorage['document' + id ] = JSON.stringify($scope.active);
        var syncList = localStorage['syncList'];
        if (syncList) {
            if (syncList.indexOf(' ' + id + ',') < 0) {
                localStorage['syncList'] += ' ' + id + ',';
            }
        } else {
            localStorage['syncList'] = ' ' + id + ',';
        }
        $scope.setLocal(id, true);
    };

    $scope.postNewDocumentToServer = function() {
        $scope.$broadcast('postNewDocument');
    };

    $scope.postNewFolderToServer = function(path, title, tempId, callback) {
        if ($scope.online && $scope.access_token) {
            $http.post(baseurl + 'api/v1/metadata/' + path + '.json?access_token=' + $scope.access_token, JSON.stringify({ title: title })).then( function(response) {
                var newId = response.headers()['x-ressourceident'];
                $scope.setNewId(tempId, newId);

                if (callback) callback();
            });
        }
    };

    $scope.$on('openDocumentRequest', function(e, data) {
        $scope.getDocument(data.id, function() {
            $scope.active = this;
            $scope.$broadcast('openDocument');
        });
    });

    var setLocalTree = function(id, data, state) {
        angular.forEach(data, function(el) {
            if (el.document_count > 0) {
                angular.forEach(el.documents, function(el) {
                    if (el.id == id) {
                        el.local = state;
                    }
                });
            }

            if (el.children_count > 0) {
                setLocalTree(id, el.folders, state);
            }
        });
    };
    $scope.setLocal = function(id, state) {
        setLocalTree(id, $scope.documents, state);
        angular.forEach($scope.files, function(el) {
            if (el.id == id) {
                el.local = state;
            }
        });
        localStorage['documents'] = JSON.stringify($scope.documents);
        localStorage['files'] = JSON.stringify($scope.files);
    };

    var $views = $('.views').children().hide().eq(1).show().end();
    $scope.showView = function(sel) {
        $views.hide();
        $views.filter('.' + sel).show();
    };

    $scope.setAccessToken = function(access_token) {
        $scope.access_token = access_token;
    };
    $scope.setRefreshToken = function(refresh_token) {
        $scope.refresh_token = refresh_token;
    };

    $scope.setActive = function(active) {
        $scope.active = active;
    };

    var filterDocumentsById = function(id, data) {
        var result = false;
        angular.forEach(data, function(el) {
            if (!result && el.document_count > 0) {
                var path = el.path;
                angular.forEach(el.documents, function(el) {
                    if (el.id == id ) {
                        result = el;
                        result.path = path;
                    }
                });
            }

            if (!result && el.children_count > 0) {
                result = filterDocumentsById(id, el.folders);
            }
        });

        return result;
    };
    $scope.setInfoDocument = function(id) {
        $scope.info = filterDocumentsById(id, $scope.documents);
    };

    var setNewId = function(id, data, newId) {
        var result = false;
        angular.forEach(data, function(el) {
            if (!result && el.document_count > 0) {
                angular.forEach(el.documents, function(el) {
                    if (el.id == id ) {
                        el.id = newId;
                        result = true;
                    }
                });
            }

            if (!result && el.children_count > 0) {
                angular.forEach(el.folders, function(el) {
                    if (el.id == id ) {
                        el.id = newId;
                        result = true;

                        if (el.children_count > 0) {
                            angular.forEach(el.folders, function(el) {
                                el.root = newId;
                            });
                        }
                    }
                });
            }

            if (!result && el.children_count > 0) {
                result = setNewId(id, el.folders, newId);
            }
        });

        return result;
    };
    $scope.setNewId = function(id, newId) {
        setNewId(id, $scope.documents, newId);
        angular.forEach($scope.files, function(el, i) {
            if (el.id == id) {
                el.id = newId;
            }
        });

        localStorage['documents'] = JSON.stringify($scope.documents);
        localStorage['files'] = JSON.stringify($scope.files);
    };

    $scope.showDocumentInfo = function() {
        if (!$scope.info) {
            alert('No active document!');
        } else {
            $('#fileInfosModal').modal('show');
        }
    };

    $scope.$broadcast('reloadDocuments');
}