function AppCtrl($scope, $http) {
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
                var syncList = localStorage['syncList'];
                if (syncList) {
                    var temp = $scope.active;
                    angular.forEach(syncList.split(','), function(el) {
                        $scope.active = JSON.parse(localStorage['document' + el]);
                        if ($scope.active) {
                            if (el.indexOf('temp') < 0) {
                                $scope.saveDocument();
                            } else {
                                $scope.saveNewDocument();
                            }
                        }
                    });
                }
            }
        };

        window.addEventListener("online", $scope.setOnlineStatus, false);
        window.addEventListener("offline", $scope.setOnlineStatus, false);
    }

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
            alert('Es ist keine Verbindung zum Server möglich und lokal sind keine gecachten Dateien vorhanden.');
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
                callback.bind(data)();
            });
        } else if (localStorage['document' + id]) {
            callback.bind(JSON.parse(localStorage['document' + id]))();
        } else if (!$scope.online) {
            alert('Es ist keine Verbindung zum Server möglich und lokal sind keine gecachten Dateien vorhanden.');
        }
    };

    $scope.newDocument = function() {
        $scope.$broadcast('newDocument');
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

    $scope.postNewToServer = function() {
        if ($scope.online && $scope.access_token && false) {
            //http-request post
            //http-request getDocuments
        } else {
            $scope.saveToSyncList();
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

    $scope.showDocumentInfo = function() {
        if (!$scope.info) {
            alert('No active document!');
        } else {
            $('#fileInfosModal').modal('show');
        }
    };

    $scope.$broadcast('reloadDocuments');
}