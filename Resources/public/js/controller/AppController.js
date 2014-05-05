function AppCtrl($scope, $http) {
    $http.defaults.headers.common.Accept = 'application/json';
    $scope.online = navigator.onLine;
    $scope.access_token = false;
    $scope.refresh_token = false;
    $scope.documents = [];
    $scope.active = false;
    $scope.info = false;
    $scope.loading = false;
    $scope.reloadDocumentsWaiting = false;
    $scope.reloadDocumentsLoading = false;

    if (window.addEventListener) {
        $scope.setOnlineStatus = function() {
            $scope.online = navigator.onLine;

            if (!navigator.onLine) {
                $scope.access_token = false;
            } else {
                $scope.$broadcast('sync');
            }
        };

        window.addEventListener('online', $scope.setOnlineStatus, false);
        window.addEventListener('offline', $scope.setOnlineStatus, false);
    }

    $scope.$on('sync', function() {
        if ($scope.online && $scope.access_token) {
            var syncList = $scope.getLocal('syncList');
            if (syncList) {
                $scope.syncDocuments = $scope.documents;
                var id = syncList.split(',').shift().trim();

                if ($scope.getLocal('document' + id)) {
                    if ((id + '').indexOf('temp') < 0) {
                        $scope.$broadcast('syncDocument', { id: id });
                    } else {
                        $scope.$broadcast('syncNewDocument', { id: id });
                    }
                } else {
                    $scope.$broadcast('sync');
                }
            } else {
                var syncErrorList = $scope.getLocal('syncErrorList');
                if (syncErrorList) {
                    $scope.setLocal('syncList', syncErrorList);
                }

                $scope.$emit('reloadDocuments');
            }
        }
    });

    var mergeServerAndLocalstorage = function(localDocuments, serverDocuments) {
        angular.forEach(localDocuments, function(localEl, key) {
            var serverEl = (serverDocuments && serverDocuments[key])? serverDocuments[key] : false;
            if (!serverEl) {
                serverEl = localEl;
                serverDocuments[key] = localEl;
            }
            if (localEl.document_count > 0) {
                angular.forEach(localEl.documents, function(localChildEl, key) {
                    if (!localChildEl.id || (localChildEl.id + '').indexOf('temp') < 0) { return true; }
                    var exists = false;
                    if (serverEl.document_count > 0) {
                        angular.forEach(serverEl.documents, function(serverChildEl, key) {
                            if (serverChildEl.id == localChildEl.id) {
                                exists = true;
                            }
                        });
                    }

                    if (!exists) {
                        serverEl.document_count++;
                        serverEl.documents.push(localChildEl);
                    }
                });
            }

            if (localEl.children_count > 0) {
                mergeServerAndLocalstorage(localEl.folders, serverEl.folders);
            }
        });
    },filterFiles = function(documents) {
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
        if ($scope.reloadDocumentsLoading) {
            $scope.reloadDocumentsWaiting = true;
        } else {
            $scope.reloadDocuments();
        }
    });

    $scope.reloadDocuments = function() {
        if ($scope.online && $scope.access_token) {
            $scope.reloadDocumentsLoading = true;
            $scope.showLoader();
            $http.get(baseurl + 'api/v1/metadata.json?access_token=' + $scope.access_token, {cache:false}).success(function (data) {
                if ($scope.getLocal('documents')) { mergeServerAndLocalstorage(JSON.parse($scope.getLocal('documents')), data); }

                $scope.documents = data;
                $scope.files = filterFiles(data);

                var documentList = $scope.getLocal('documentList');
                if (documentList) {
                    angular.forEach(documentList.split(','), function(el) {
                        id = el.trim();
                        if (id > 0) {
                            $scope.setDocumentLocalAttr(id, true);
                        }
                    });
                }

                $scope.updateLocalDocuments();

                $scope.reloadDocumentsLoading = false;

                if ($scope.reloadDocumentsWaiting) {
                    $scope.reloadDocumentsWaiting = false;
                    $scope.$broadcast('reloadDocuments');
                }

                $scope.hideLoader();
            }).error(function(data, status) {
                $scope.hideLoader();
                $scope.checkOnline(status, function() { $scope.reloadDocuments(); });
            });
        } else if ($scope.getLocal('documents') && $scope.getLocal('files')) {
            $scope.documents = JSON.parse($scope.getLocal('documents'));
            $scope.files = JSON.parse($scope.getLocal('files'));
        } else {
            // We need to load demo data synchronously because demo data needs to be
            // locally available before we continue initializing mono:di

            var request = new XMLHttpRequest();
            request.open('GET', '/bundles/digitalwertmonodiclient/js/demo.json', false);  // `false` makes the request synchronous
            request.send(null);

            if (request.status === 200) {
              $scope.documents = JSON.parse(request.responseText);
              $scope.files = extractFiles($scope.documents);
              $scope.setLocal("documents", JSON.stringify($scope.documents));
              $scope.setLocal("files", JSON.stringify($scope.files));
              $scope.files.forEach(function(file){
                $scope.addToDocumentList(file.id, file);
              });
            } else {
              alert("The mono:di demo data could not be loaded");
            }
        }
    };

    function extractFiles(folderList) {
      var documentList = [],
          documentsInFolder;
      folderList.forEach(function(folder) {

        documentList = documentList.concat(folder.documents || []);
        if (folder.folders) {
          folder.folders.forEach(function(subfolder) {
            var documentsInFolder = extractFiles(subfolder.folders);
            documentList = documentList.concat(documentsInFolder);
          });
        }
      });
      return documentList;
    }


    $scope.getDocument = function(id, callback) {
        if ($scope.online && $scope.access_token && (id + '').indexOf('temp') == -1) {
            $scope.showLoader();
            $http.get(baseurl + 'api/v1/documents/' + id + '.json?access_token=' + $scope.access_token).success(function (data) {
                callback.bind(data)();
                $scope.hideLoader();
            }).error(function(data, status) {
                $scope.hideLoader();
                $scope.checkOnline(status);
            });
        } else if ($scope.getLocal('document' + id)) {
            callback.bind(JSON.parse($scope.getLocal('document' + id)))();
        } else if (!$scope.online) {
            alert('You are working offline and the ressource is locally not available.');
        } else {
            alert('Please log in to proceed.');
        }
    };

    var removeDocumentFromTree = function(id, data) {
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
                removed = removeDocumentFromTree(id, el.folders);
            }
        });

        return removed;
    },
    removeDocument = function(id) {
        removeDocumentFromTree(id, $scope.documents);
        angular.forEach($scope.files, function(el, i) {
            if (el.id == id) {
                $scope.files.splice(i,1);
            }
        });

        $scope.updateLocalDocuments();
    };
    $scope.deleteDocument = function(id, callback) {
        if ((id + '').indexOf('temp') < 0) {
            $scope.showLoader();
            $http['delete'](baseurl + 'api/v1/documents/' + id + '.json?access_token=' + $scope.access_token)
                .success( function() {
                    removeDocument(id);
                    if (callback) callback();
                    $scope.hideLoader();
                }).error(function(data, status) {
                    $scope.hideLoader();
                    $scope.checkOnline(status);
                    if (status == '401') {
                        alert('Please log in to delete the file from the server.');
                    } else if (status == '403') {
                        alert('You are not the owner of this file. Only the owner and a super-administrator can delete this file.');
                    } else {
                        alert('The document could not be deleted on the server. Please try again or contact the administrator (error-code ' + status + ').');
                    }
                });
        } else {
            removeDocument(id);
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

    $scope.postNewDocumentToServer = function() {
        $scope.$broadcast('postNewDocument');
    };

    $scope.postNewFolderToServer = function(path, title, tempId, callback) {
        if ($scope.online && $scope.access_token) {
            $scope.showLoader();
            $http.post(baseurl + 'api/v1/metadata/' + path + '.json?access_token=' + $scope.access_token, JSON.stringify({ title: title }))
            .success( function(response, status, headers) {
                var newId = headers()['x-ressourceident'];
                $scope.setNewId(tempId, newId);

                if (callback) callback();
                $scope.hideLoader();
            }).error( function(data, status) {
                $scope.hideLoader();
                $scope.checkOnline(status);
            });
        }
    };

    $scope.$on('openDocumentRequest', function(e, data) {
        if ($scope.active) {
            if (!confirm('Leave this document? Please make sure you have saved changes.')) {
                return;
            }
        }

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
    $scope.setDocumentLocalAttr = function(id, state) {
        setLocalTree(id, $scope.documents, state);
        angular.forEach($scope.files, function(el) {
            if (el.id == id) {
                el.local = state;
            }
        });
        $scope.updateLocalDocuments();
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

        var local = $scope.getLocal('document' + id);
        if (local) {
            $scope.removeLocal('document' + id);
            $scope.setLocal('document' + newId, local);
        }

        var documentList = $scope.getLocal('documentList');
        if (documentList) {
            if (documentList.indexOf(' ' + id + ',') > -1) {
                $scope.setLocal('documentList', documentList.replace(' ' + id + ',', ''));
            }

            $scope.setLocal('documentList', documentList + ' ' + newId + ',');
        } else {
            $scope.setLocal('documentList', ' ' + newId + ',');
        }

        $scope.updateLocalDocuments();
    };

    $scope.showDocumentInfo = function() {
        if (!$scope.info) {
            alert('No active document!');
        } else {
            $('#fileInfosModal').modal('show');
        }
    };

    $scope.setLocal = function(key, value) {
        try {
            localStorage[key] = value;
        } catch(e) {
            alert('The local storage in your browser is full.\n\nIf you receive this message while logging in, please go to the management page , remove some files (in any folder) from local storage by clicking the yellow button next to the file name (more conveniently done in the document list view), and reload the page.\n\nIf you receive this message while saving a document, please go to the management page, remove some files (in any folder) from local storage by clicking the yellow button next to the file name (more conveniently done in the document list view), return to the document, and save again.');
        }
    };

    $scope.getLocal = function(key) {
        return localStorage[key];
    };

    $scope.removeLocal = function(key) {
        localStorage.removeItem(key);
    };

    var removeContentAttr = function(data) {
        angular.forEach(data, function(el) {
            if (el.document_count > 0) {
                angular.forEach(el.documents, function(el) {
                    if (el.content) {
                        delete el.content;
                    }
                });
            }

            if (el.children_count > 0) {
                removeContentAttr(el.folders);
            }
        });
    };
    $scope.updateLocalDocuments = function() {
        var documents = $.map($.extend(true, {}, $scope.documents), function(v) {
            return v;
        }), files = $.map($.extend(true, {}, $scope.files), function(v) {
            return v;
        });

        removeContentAttr(documents);
        $scope.setLocal('documents', JSON.stringify(documents));

        angular.forEach(files, function(el) {
            if (el.content) {
                delete el.content;
            }
        });
        $scope.setLocal('files', JSON.stringify(files));
    };

    $scope.saveToSyncList = function() {
        var id = $scope.active.id;

        $scope.active.content = monodi.document.getSerializedDocument();

        $scope.setLocal('document' + id, JSON.stringify($scope.active));
        var syncList = $scope.getLocal('syncList');
        if (syncList) {
            if (syncList.indexOf(' ' + id + ',') < 0) {
                $scope.setLocal('syncList', syncList + ' ' + id + ',');
            }
        } else {
            $scope.setLocal('syncList', ' ' + id + ',');
        }
        $scope.setDocumentLocalAttr(id, true);
    };

    $scope.isOnSyncList = function(id) {
        var syncList = $scope.getLocal('syncList');
        if (syncList) {
            return syncList.indexOf(' ' + id + ',') > -1;
        }

        return false;
    };

    $scope.removeFromSyncList = function(id) {
        var syncList = $scope.getLocal('syncList');
        if (syncList) {
            $scope.setLocal('syncList', syncList.replace(' ' + id + ',', ''));
        }
    };

    $scope.addToDocumentList = function(id, content) {
        $scope.setLocal('document' + id, JSON.stringify(content));
        var documentList = $scope.getLocal('documentList');
        if (documentList) {
            if (documentList.indexOf(' ' + id + ',') < 0) {
                $scope.setLocal('documentList', documentList + ' ' + id + ',');
            }
        } else {
            $scope.setLocal('documentList', ' ' + id + ',');
        }
        $scope.setDocumentLocalAttr(id, true);
    };

    $scope.showLoader = function() {
        $scope.loading = true;
    };

    $scope.hideLoader = function() {
        if (!$http.pendingRequests.length) {
            $scope.loading = false;
        }
    };

    $scope.checkOnline = function(status, callback) {
        if (!callback) {
            callback = function() { alert('You are not connected to the server. Please check your internet connection.'); };
        }

        if (status == 0) {
            $scope.access_token = false;
            callback();
        }
    };

    $scope.$broadcast('reloadDocuments');
}
